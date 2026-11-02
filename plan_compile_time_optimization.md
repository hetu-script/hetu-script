# 编译期优化工具实施计划

## 文档说明

本计划只针对运行性能，不增加脚本语法、类型、标准库功能或静态诊断要求。目标是在编译期确定变量绑定、存储位置和常量表达式结果，减少运行期 namespace 递归查找、完整调用命名空间分配和重复计算。

状态分为“待执行”“当前执行”“已完成”和“暂缓”。每个阶段独立建立基线、实现、测试、测量并决定保留或撤回，不预设提速倍数。

与既有计划的关系：

- `plan_function_call_performance.md` 的步骤一至五已完成，步骤六至十三仍暂缓。
- 本计划补充原步骤六、七所需的编译期基础设施，不自动恢复共享操作数栈、quickening、专用调用指令、异步调度或原生核心改造。
- `plan_namespace_performance.md` 中“调用帧与命名空间分离”的方向由本计划具体化。
- 实施前先保存当前工作，并记录基线提交哈希；不在同一改动中混入其他优化。

## 目标与非目标

### 目标

- 为局部变量提供编译期槽位，替代热点字符串 map 查找。
- 区分未捕获变量、闭包捕获变量、模块声明和必须动态解析的访问。
- 用轻量调用作用域替代普通函数调用中的完整 `HTNamespace`，保留现有解释器上下文和操作数栈模型。
- 在安全前提下折叠常量表达式，并直接生成常量加载指令。
- 保留动态执行、模块重载、调试信息和错误位置的可用性。

### 非目标

- 不补全静态类型检查、类型推断、诊断或分析器功能。
- 不增加 tuple、Record、语法、类型声明或新的运行时功能。
- 不要求启用 `doStaticAnalysis`，不默认增加静态警告。
- 不整体替换模块、类和 struct 使用的 `HTNamespace`。
- 不实施共享操作数栈、帧池化、quickening、`call0`、尾调用、异步调度或 C/Rust 核心。
- 不引入第三方依赖。

## 现状与实施依据

- 普通脚本函数每次调用都会创建完整调用 `HTNamespace`，参数和局部变量通过符号查找：`packages/hetu_script/lib/value/function/function.dart`。
- `HTNamespace.memberGet` 支持闭包链递归查找，局部访问也承担 map、声明解析和虚拟调用成本：`packages/hetu_script/lib/value/namespace/namespace.dart:31`。
- 现有 `HTAnalyzerImpl` 主要检查标识符是否存在，没有槽位、捕获或存储类别等优化产物。
- `HTTypeChecker` 对多数表达式返回 `any`，不作为本计划的前置条件。
- `constant_interpreter` 主要计算 `const` 声明；`compileAST()` 不会把一般折叠表达式统一生成为常量加载，因此仅扩充求值 visitor 无法减少运行期指令。
- 当前常量实现还存在需要规避的语义限制：三元条件判断不完整，短路表达式不能直接按普通二元运算处理，null、除零、调用和成员访问不能贸然折叠。

## 总体设计

### 编译期产物

新增独立的优化解析器，不改变现有诊断分析器。分析结果仅属于当前 compilation，不使用全局缓存。

建议的数据结构（名称可在实现时按项目惯例调整）：

```dart
enum HTResolvedStorage {
  localSlot,
  capturedCell,
  moduleDeclaration,
  dynamic,
}

class HTResolvedVariable {
  final ASTNode declaration;
  final String name;
  final HTResolvedStorage storage;
  final int? slot;
}

class HTResolvedReference {
  final HTResolvedVariable variable;
  final HTResolvedStorage storage;
}

class HTFunctionOptimization {
  final HTResolvedScope scope;
  final int localSlotCount;
  final List<HTResolvedVariable> capturedVariables;
}

class HTOptimizationResult {
  final Map<ASTNode, HTResolvedReference> references;
  final Map<ASTNode, HTFunctionOptimization> functions;
}
```

约束：

- Map 以 AST 节点身份为 key，生命周期与 compilation 一致。
- 槽位只在函数及其词法块内分配；变量遮蔽使用不同声明身份，不依赖名称去重。
- 默认值表达式保留原执行路径和执行时机，不在解析阶段求值。
- 无法可靠解析的引用标记为 `dynamic`，不产生错误，也不阻止编译。
- 调试信息保留 slot 到变量名的映射。

### 运行时表示

新增轻量调用作用域和捕获 cell，概念如下：

```dart
class HTCallScope {
  final List<dynamic> slots;
  final HTCallScope? closure;
}

class HTVariableCell {
  dynamic value;
}
```

- 未捕获局部变量使用 slot 数组。
- 被内部函数捕获的变量使用 cell，函数返回后仍由闭包持有。
- 不全局池化调用作用域或 cell，异步和闭包生命周期优先于复用。
- `HTNamespace` 继续服务模块、类、struct、导入导出和动态回退。
- `HTContext`、操作数栈、异常和 `FutureExecution` 的保存恢复方式先保持不变。

## 阶段零：保存基线与建立语义矩阵（待执行）

### 工作内容

- 记录基线提交、Dart SDK、机器和电源状态。
- 为现有行为补充测试，不要求新分析产物：
  - 位置参数、可选参数、命名参数、默认值和 `_`。
  - 变量遮蔽、赋值、删除、递归、提前返回和异常。
  - 闭包捕获、循环闭包、捕获后修改和函数身份。
  - 类、struct、构造函数字段初始化、外部绑定。
  - 异步挂起恢复、模块切换和重复加载。
- 新增两个性能脚本草案：
  - `test/performance/scope_local.dart`：局部变量密集读写、未捕获闭包、捕获变量和动态回退。
  - `test/performance/constant_fold.dart`：可折叠表达式、不可折叠动态对照、编译耗时和字节码大小。

### 验收

- 基线测试全部通过。
- 所有性能场景预热后至少测量 5 次，保留原始样本、中位数和校验值。
- 记录 JIT/AOT 耗时、编译耗时、字节码大小和分配基线，而不只记录 `fib`。

## 阶段一：只读词法作用域与引用解析（待执行）

本阶段只生成元数据，不改变字节码或运行时行为。

### 工作内容

建议新增：

- `packages/hetu_script/lib/analyzer/optimization/optimization_result.dart`
- `packages/hetu_script/lib/analyzer/optimization/optimization_resolver.dart`
- `test/analyzer/optimization_resolver_test.dart`

解析器至少执行两次遍历：

1. 建立函数和词法块作用域、声明身份及槽位候选。
2. 解析标识符引用，并标记局部、捕获、模块或动态存储。

覆盖：

- 参数、局部变量、函数声明、块级遮蔽。
- 嵌套函数、立即执行函数、箭头函数和递归。
- 普通 for、for-in 及编译器现有的循环变量改写。
- 默认参数中的引用，但不执行默认值。
- 类、struct、命名空间、导入和外部声明的保守回退。

### 验收

- 元数据测试证明同一声明的引用一致，遮蔽声明彼此独立。
- 捕获判断只依赖真实引用关系，不因同名变量误捕获。
- 动态或暂不支持的结构得到明确回退标记。
- 未改变任何执行结果，默认不增加诊断。

## 阶段二：未捕获局部变量槽位（待执行）

### 工作内容

修改编译器和函数调用路径：

- 为未捕获参数和局部变量分配 slot。
- 增加局部槽位读写指令及 uint16 槽位编码，保留动态 identifier 回退。
- 普通函数创建轻量调用作用域；不再为纯局部访问创建完整符号 namespace。
- 参数绑定继续支持默认值、可选参数和 `_`，复杂函数可继续使用通用路径。
- 保留 `this`、super、构造调用、外部调用、异常和异步上下文。
- 同步字节码版本，并重新生成预编译标准库：
  `dart run utils/compile_hetu.dart`

### 验收

- 阶段零语义矩阵及全量测试通过。
- 新增槽位边界、遮蔽、默认值、提前返回和字节码兼容测试。
- 比较 `fib`、`empty`、`identity`、局部变量密集循环和动态回退。
- 通过分配分析确认未捕获局部环境的分配量下降。
- 若只有轻微收益但明显增加调用路径复杂度，暂停后续阶段并复核。

## 阶段三：闭包捕获 cell（待执行）

### 工作内容

- 仅把真实被捕获的局部变量放入 cell，未捕获变量继续使用 slot。
- 内部函数保存正确的捕获作用域，函数返回后 cell 仍存活。
- 保持循环闭包身份、每轮捕获、捕获后赋值和递归行为。
- 异步挂起、嵌套外部回调和 `FutureExecution` 恢复继续保存完整上下文。
- 不做无逃逸分析的全局作用域复用。

### 验收

- 覆盖循环闭包、捕获后修改、递归、函数身份、嵌套回调和异步恢复。
- 比较 `closure`、`fib` 和捕获密集场景，同时检查未捕获场景没有明显回退。
- 分配分析区分 slot 与 cell，确认没有给所有局部变量增加捕获成本。

## 阶段四：模块声明与动态回退优化（待评估）

本阶段在前述实现稳定后进行，不是槽位化的必要条件。

### 工作内容

- 模块变量先继续使用现有 namespace，避免同时重写模块生命周期。
- 对稳定模块函数或变量评估直接声明缓存，必须带模块代次或声明版本。
- 对成员访问、动态赋值、删除、动态 `eval`、导入和模块重载保留动态路径。
- 如果直接缓存没有稳定收益，则本阶段撤回，不影响局部 slot 和捕获 cell。

### 验收

- 覆盖同名模块、声明替换、模块重复执行、导入和动态删除。
- 记录缓存命中率、失效率和失效正确性，不只比较总耗时。

## 阶段五：有限常量折叠管线（待执行）

本阶段可以独立于 slot 实施，但应先完成或明确跳过前序阶段，避免混淆性能来源。

### 工作内容

- 新增独立 `HTConstantFolder`，或将现有 `constant_interpreter` 收敛为语义明确的实现。
- 复用现有 `computeConstantExpression`，使其不再依赖 `doStaticAnalysis`；默认值保持 false。
- 编译器在得到折叠结果时直接生成 bool、int、double 或 String 常量加载。
- 第一版仅支持：
  - 字面量、分组和已解析的 const 标识符。
  - 安全的数值、布尔和比较运算。
  - 字符串插值中的基本常量。
  - 保留短路语义的 `&&`、`||`、`??` 和三元表达式。
- 不折叠 null、除零、函数调用、成员访问、集合操作或具有副作用的表达式。
- 不把分析期异常变成新的默认编译错误。

### 验收

- 每个支持和不支持的表达式都有结果及字节码对照。
- 明确测试短路、除零、默认值、常量标识符和动态变量。
- 比较编译耗时、字节码大小、JIT/AOT 执行耗时；常量密集场景与动态对照同时记录。
- 如果只有字节码缩小而没有稳定运行收益，不默认开启。

## 阶段六：硬化与应用级验收（待执行）

- 运行全量测试、相关 analyze、格式检查和 AOT 实际执行。
- 覆盖压力递归、深层表达式、循环闭包、异步嵌套、模块重载和长时间分配/GC。
- 分别记录每阶段保留、撤回和未确认的结果。
- 在真实 Flutter/Flame 游戏 profile 模式下验证帧耗时、脚本耗时和分配。
- 若真实游戏没有改善，停止扩大到 quickening、共享操作数栈或其他结构性改造。

## 基准与统一验收标准

每个阶段至少执行：

```bash
dart test
dart analyze <本阶段修改文件>
dart run test/performance/fib.dart
dart run test/performance/function_call.dart
dart run test/performance/binding_call.dart
dart run test/performance/scope_local.dart
dart run test/performance/constant_fold.dart
```

AOT 使用独立可执行文件，优化前后在相同机器状态下交替运行。每个场景预热后至少测量 5 次并取中位数，小于约 5% 的差异先视为噪声。

每个阶段的保留条件：

- 现有和新增测试全部通过，脚本结果及错误行为不变。
- 目标场景有重复收益，其他场景没有无法解释的明显回退。
- 分配优化有分配量证据，缓存有生命周期和失效测试。
- 编译耗时、启动耗时、字节码大小和额外内存没有被隐藏。
- 收益处于噪声而复杂度明显增加时，保留简单原实现并记录撤回原因。
- 真实游戏验证前，不把 JIT 比例外推到 Flutter AOT 或帧率提升。

## 预计主要修改范围

新增：

- `packages/hetu_script/lib/analyzer/optimization/`
- `packages/hetu_script/lib/value/call_scope/`
- `test/analyzer/optimization_resolver_test.dart`
- `test/performance/scope_local.dart`
- `test/performance/constant_fold.dart`

按阶段修改：

- `packages/hetu_script/lib/bytecode/compiler.dart`
- `packages/hetu_script/lib/bytecode/op_code.dart`
- `packages/hetu_script/lib/interpreter/interpreter.dart`
- `packages/hetu_script/lib/value/function/function.dart`
- `packages/hetu_script/lib/constant/constant_interpreter.dart` 或新的 `constant_folder.dart`
- `packages/hetu_script/lib/preinclude/hetu.dart`

预编译文件只通过 `dart run utils/compile_hetu.dart` 生成，不手工编辑。

## 默认决策

- 新建独立优化解析器，不扩充旧静态类型检查作为性能前置。
- 先完成未捕获 slot，再实现捕获 cell，避免一次性重写所有变量存储。
- 动态语义始终优先于静态推断，无法证明安全时回退到现有 namespace。
- 常量折叠是独立优化，不要求启用静态分析，也不默认开启。
- 阶段四和后续专用指令必须重新评估，不因完成本计划而自动实施。
