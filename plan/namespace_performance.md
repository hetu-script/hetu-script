性能分析：fib(30) 9秒的问题
先说结论：对于当前的架构设计，9秒跑完 fib(30) 是 差但有合理解释，有巨大改进空间。作为对比，同样用 Dart 写一个解释型脚本语言，一个相对高效的实现应该能在 0.5-2 秒内跑完（Debug 模式）。

fib(30) 执行量级
fib(30) 约产生 269万次函数调用，每次调用涉及数十条字节码。总体操作量级大约：

操作 次数
函数调用 ~2,690,000
变量访问 (n) ~2,690,000
变量访问 (n-1, n-2 的参数求值) ~5,380,000
算术运算 (n-1, n-2, +) ~2,690,000+
函数名查找 (fib 递归) ~5,380,000
HTNamespace 是不是最大瓶颈？
不精确地说是 HTNamespace 的创建，而不是它的 memberGet。具体来说，主要热点排序：

🔴 瓶颈 #1：每次函数调用创建完整的 HTNamespace（最大开销）
function.dart:379-383 — 每次调用都创建一个全新命名空间：

final HTNamespace callClosure = HTNamespace(
lexicon: interpreter.lexicon,
id: internalName,
closure: useCallingNamespace ? namespace : closure as HTNamespace?);
而 HTNamespace 的构造函数 (declaration_namespace.dart:38-46) 立即遍历整个 closure 链计算 \_fullName，且分配了完整的 symbols、importedSymbols、imports、exports 等 Map 对象。

对于 fib(30)，这意味着：

269万个 HTNamespace 对象分配
269万次 \_fullName 字符串拼接
每个 callClosure 实际只用到了 1 个符号 (n)，却分配了 5 个 Map
🔴 瓶颈 #2：HTValueBinding 包装
function.dart:447-448 — 每个参数都用 HTValueBinding 包一层：

callClosure.define(paramId, HTValueBinding(id: paramDecl.id, value: paramValue));
对于 fib(30)，每个调用定义 1 个参数 → 269万个 HTValueBinding 分配。然后每次访问 n 时，memberGet 找到 HTValueBinding，调用 decl.resolve() (virtual call)，再调用 decl.value (virtual call)，得到真正的数值。

🟡 瓶颈 #3：每次变量访问走 memberGet + isRecursive
interpreter.dart:2558：

stack.push(currentNamespace.memberGet(symbol, isRecursive: true));
fib 函数体内每次出现 n，都会 walk 命名空间链：查 callClosure.symbols（命中）→ 提取 declaration → resolve() → .value。虽然参数在自身 symbols 中能找到，不需要走到 closure，但 containsKey（string hash）+ is HTDeclaration 类型检查 + resolve() virtual call + .value virtual call 仍然有客观开销。

🟡 瓶颈 #4：BytecodeReader.read() 的 IP 边界检查
bytecode_reader.dart:22-29 — 每个字节码字节都做边界检查。269万次调用 × 每次约 20+ 条字节码指令 × 每条指令多字节 ≈ 上亿次边界检查。

🟢 瓶颈 #5（次要）：HTNamespace 中的 fullName 隐私检查
在 memberGet 的隐私检查 (namespace.dart:63-64)：

if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
对于 fib 这种无闭包嵌套的递归，这个检查不触发也没用，但 fullName 本身的计算（构造函数中 walk closure 链）已经消耗了时间。

改进建议（按投入产出比排序）

1. ⭐ 轻量级调用帧替代 HTNamespace（高投入产出比）
   为函数调用设计一个 HTCallFrame 类，内部用一个数组存储参数值，不分配 Map。变量访问从 currentNamespace.memberGet("n", isRecursive: true) 改为 callFrame.get(0) 按索引查找。

class HTCallFrame {
final List<dynamic> \_locals;
final HTNamespace? closure; // 只保留用于闭包的引用

dynamic get(int index) => \_locals[index];
void set(int index, dynamic value) => \_locals[index] = value;
}
编译时，编译器知道 n 是函数的第几个参数，直接 emit loadLocal 0 而不是 identifier "n" + memberGet。

预期收益：消除对象分配和 map 查找，对 fib 这类递归函数可能有 3-5倍 速度提升。

2. ⭐ 延迟计算 \_fullName（低投入，中等产出）
   在 HTDeclarationNamespace 构造函数中，把 \_fullName 的计算改为 lazy：

String? \_fullName;
String get fullName {
if (\_fullName != null) return \_fullName!;
// compute lazily
}
预期收益：对于 callClosure（从不使用 fullName），完全消除构造函数中的链式遍历和字符串拼接。

3. ⭐ 移除 BytecodeReader.read() 的生产环境边界检查

int read() {
return bytes[ip++]; // 信任编译器生成的字节码
}
可以用 assert 保留调试模式的检查。预期收益：减少每条字节码指令的分支开销。

4. 编译时变量索引化
   在编译阶段，对于函数内的局部变量（参数 + 局部 var），直接解析为栈索引。不需要在运行时通过名称查 Map。

预期收益：变量访问从 O(map lookup) + virtual calls 变为 O(1) 数组索引。

5. 内联缓存 (Inline Cache)
   在 memberGet 的首个查找位置记录上一次命中信息（key + target namespace + declaration），下次相同 key 时快速命中。

预期收益：对多次访问同一变量的场景（如 fib 中的 n），从 map lookup 降级为指针比较。

6. 类型特化 / 原始数值直传
   对于 fib 这种纯整数运算的函数，如果能识别出参数和返回类型都是 int，可以直接在栈上操作原始 int，不做 HTValueBinding 包装和类型封装。

总结
HTNamespace 本身的设计是合理的——作为全局/模块/类的命名空间，它的功能完整性和正确性没有问题。问题在于它被误用为每次函数调用的运行时作用域。为 fib 的每一层递归都完整创建命名空间（含5个Map），如同用 HashMap 来实现 C 的栈帧——功能可行，但性能代价过高。

建议的优化重点是：把 "调用帧" 和 "命名空间" 拆开。调用帧用简单的数组，命名空间保持现有设计用于模块/类级别。这会给 fib(30) 带来数量级的性能提升。
