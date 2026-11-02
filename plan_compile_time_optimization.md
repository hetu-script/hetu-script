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

## 阶段零：保存基线与建立语义矩阵（已完成）

完成日期：2026-11-03。运行时代码基线提交：`f5ffde82c257bdaa3fed7f3076c569d9f2fa02e6`。开始前工作树只有 `plan_function_call_performance.md` 的文档改动，不影响运行时基线；本阶段没有修改编译器、解释器或预编译标准库。

### 已完成内容

- 新增 `test/interpreter/optimization_semantics_test.dart`，以 11 项测试覆盖参数、默认值、变量遮蔽、赋值、删除、递归、提前返回、异常、闭包、类、struct、外部回调、异步恢复和模块生命周期。
- 新增 `test/performance/scope_local.dart`，覆盖 `local`、`uncaptured_closure`、`captured_variable` 和 `dynamic_fallback`。
- 新增 `test/performance/constant_fold.dart`，覆盖 `foldable` 和 `dynamic`，分别记录编译样本、执行样本和字节码大小。
- 调整 `test/performance/fib.dart` 的计时代码为预热后测量 5 次，递归脚本和解释器配置保持不变。
- 基线行为已按现状固定：默认参数重复读取当前得到 `[1, 1, 1]`；直接捕获普通 for 循环变量的三个闭包当前都得到最终值 `3`，但闭包身份不同。后续优化不得在无单独语义决策的情况下改变这些结果。

### 基线环境

| 项目 | 记录 |
| --- | --- |
| Dart SDK | 3.13.2 stable，windows_x64 |
| 操作系统 | Microsoft Windows 10 专业版 10.0.19045 |
| CPU | Intel Core i9-14900KF，32 逻辑处理器 |
| 内存 | 31.84 GiB |
| 电源计划 | 高性能，GUID `8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c` |

所有耗时样本单位均为微秒，以下数组是排序后的五次原始测量值。每个场景均已预热并核对校验值，耗时比较使用中位数，不把分配采样模式的耗时与普通 JIT 样本混合。

### JIT 基线

| 场景 | samples_us | 中位数 | 校验值 |
| --- | --- | ---: | ---: |
| fib | [2335119, 2335968, 2337807, 2338404, 2346924] | 2337807 | 832040 |
| constant | [99793, 101309, 101421, 112443, 151378] | 101421 | 100000 |
| utf8 | [127822, 130701, 132943, 136686, 141425] | 132943 | 100000 |
| empty | [188595, 189532, 189595, 190333, 207416] | 189595 | 200000 |
| identity | [209443, 209746, 211538, 212201, 213731] | 211538 | 200000 |
| closure | [149255, 149796, 150640, 150650, 150964] | 150640 | 100000 |
| named | [165660, 165975, 166319, 166963, 185253] | 166319 | 100000 |
| variadic | [768378, 771347, 782706, 783698, 785003] | 782706 | 100000 |
| spread | [197169, 197998, 198273, 219373, 303082] | 198273 | 100000 |
| stack_trace | [218551, 218889, 221327, 224529, 225962] | 221327 | 200000 |
| external_function | [103465, 105637, 109483, 111850, 161641] | 109483 | 100000 |
| raw_function | [104132, 104425, 104793, 118538, 148788] | 104793 | 100000 |
| external_method | [146317, 146856, 149543, 161132, 201419] | 149543 | 100000 |
| external_property | [128413, 129279, 130650, 132533, 136104] | 130650 | 100000 |
| dart_to_script | [40477, 40514, 40515, 40842, 42860] | 40515 | 100000 |
| nested_callback | [56419, 56426, 56799, 56800, 57196] | 56799 | 100000 |
| typedef_callback | [171948, 173132, 174692, 174751, 175640] | 174692 | 100000 |
| list_property | [162425, 162619, 166618, 167116, 174454] | 166618 | 100000 |
| local | [171483, 172041, 173505, 182635, 221116] | 173505 | 300003 |
| uncaptured_closure | [126332, 127695, 132423, 140361, 184949] | 132423 | 100000 |
| captured_variable | [151486, 152450, 154102, 157980, 166082] | 154102 | 100000 |
| dynamic_fallback | [129524, 129579, 130930, 146056, 147055] | 130930 | 100000 |
| foldable | [399455, 400128, 411328, 414144, 443766] | 411328 | 6100000 |
| dynamic | [539504, 541888, 544828, 546762, 549005] | 544828 | 6100000 |

### AOT 基线

| 场景 | samples_us | 中位数 | 校验值 |
| --- | --- | ---: | ---: |
| fib | [2910264, 2911520, 2919057, 2922158, 2941191] | 2919057 | 832040 |
| constant | [130443, 131456, 132286, 133760, 134871] | 132286 | 100000 |
| utf8 | [144745, 145939, 145955, 147461, 148916] | 145955 | 100000 |
| empty | [230151, 230363, 230620, 231264, 232248] | 230620 | 200000 |
| identity | [242400, 242745, 242941, 243326, 245281] | 242941 | 200000 |
| closure | [169334, 169394, 170048, 170832, 173884] | 170048 | 100000 |
| named | [187747, 188071, 188628, 189410, 192258] | 188628 | 100000 |
| variadic | [795979, 796424, 797122, 798243, 819433] | 797122 | 100000 |
| spread | [216760, 217960, 218221, 218421, 218722] | 218221 | 100000 |
| stack_trace | [243465, 244289, 244514, 244774, 247546] | 244514 | 200000 |
| external_function | [125170, 125698, 126071, 126258, 126315] | 126071 | 100000 |
| raw_function | [127935, 127943, 128582, 129674, 130556] | 128582 | 100000 |
| external_method | [163898, 164887, 164914, 165981, 166866] | 164914 | 100000 |
| external_property | [157339, 159692, 160355, 160806, 161951] | 160355 | 100000 |
| dart_to_script | [45331, 45378, 45380, 46546, 46593] | 45380 | 100000 |
| nested_callback | [62565, 62776, 62868, 62979, 64928] | 62868 | 100000 |
| typedef_callback | [196851, 197320, 197529, 198111, 204628] | 197529 | 100000 |
| list_property | [181084, 182406, 183571, 184287, 185427] | 183571 | 100000 |
| local | [216889, 217003, 218952, 220447, 221241] | 218952 | 300003 |
| uncaptured_closure | [148824, 152393, 155786, 157270, 158070] | 155786 | 100000 |
| captured_variable | [181489, 181998, 187456, 189501, 190804] | 187456 | 100000 |
| dynamic_fallback | [141841, 144631, 150400, 150853, 151532] | 150400 | 100000 |
| foldable | [446920, 446986, 447162, 449244, 452489] | 447162 | 6100000 |
| dynamic | [612514, 614024, 618659, 622395, 626188] | 618659 | 6100000 |

### 编译耗时与字节码大小

| 模式 | 场景 | 字节数 | compile_samples_us | 编译中位数 |
| --- | --- | ---: | --- | ---: |
| JIT | foldable | 880 | [1944, 2016, 2209, 2587, 3226] | 2209 |
| JIT | dynamic | 1065 | [1765, 1797, 1953, 1986, 2090] | 1953 |
| AOT | foldable | 880 | [771, 787, 818, 841, 893] | 818 |
| AOT | dynamic | 1065 | [826, 829, 837, 838, 886] | 837 |

### 分配基线

分配采样通过 Dart VM service `getAllocationProfile` 单独执行，使用 1024 MiB new-gen semi space 和 4096 MiB old-gen 上限，减少短期对象在采样前被回收的影响。统计区间包含解释器初始化、预热和五次测量，因此用于后续同口径对比，不解释为单次迭代的精确分配量，也不用于执行耗时比较。

| 场景 | 累计分配字节 | 累计实例 | HTNamespace 字节/实例 | HTContext 字节/实例 | HTStackFrame 字节/实例 | _List 字节/实例 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| local | 743823584 | 9721070 | 41366208 / 198876 | 256 / 4 | 未单列 | 243995040 / 3030177 |
| uncaptured_closure | 551353760 | 8105228 | 68659968 / 330096 | 21125248 / 330082 | 7922016 / 165042 | 146629600 / 2029547 |
| captured_variable | 975607040 | 14235689 | 148643456 / 714632 | 30490496 / 476414 | 11433984 / 238208 | 242615984 / 3621678 |
| dynamic_fallback | 159370096 | 2114374 | 10609248 / 51006 | 未单列 | 未单列 | 57438224 / 608532 |

`local` 另有 `HTVariable` 47730240 字节、198876 个实例，可作为后续块级局部变量分配优化的对照。

### 验收结果

- 修改前全量 `dart test` 为 455 项通过；加入语义矩阵后为 466 项全部通过。
- 四个新增或调整的 Dart 文件执行 `dart analyze` 无问题，格式检查通过。
- 两个新基准和 `fib` 均在 JIT 与独立 AOT 可执行文件下实际执行，所有原始样本、中位数和校验值已记录。
- 编译耗时、字节码大小及四个局部作用域场景的分配基线已记录，不只包含 `fib`。
- 本阶段未进行真实 Flutter/Flame 游戏 profile，该项仍属于阶段六，不影响阶段零完成结论。

## 阶段一：只读词法作用域与引用解析（已完成）

完成日期：2026-11-03。本阶段只新增独立解析器和元数据测试，没有接入字节码生成或运行时，也没有增加默认诊断。

### 已完成内容

新增：

- `packages/hetu_script/lib/optimization/optimization_result.dart`
- `packages/hetu_script/lib/optimization/optimization_resolver.dart`
- `test/analyzer/optimization_resolver_test.dart`

解析器按 compilation 创建独立结果，以 AST 节点身份保存引用、函数和作用域映射，执行两遍遍历：

1. 建立模块、函数、词法块和动态边界作用域，记录声明身份、函数级 slot 候选及 slot 到变量名的映射。
2. 解析实际标识符引用，标记 `localSlot`、`capturedCell`、`moduleDeclaration` 或 `dynamic`，并记录外层函数需要保留的 cell 和嵌套函数的 upvalues。

具体行为：

- 参数、局部变量、局部函数和块级遮蔽使用不同声明身份，同名声明不合并。
- 嵌套函数、箭头函数、立即执行函数和递归按真实引用判断捕获，同名参数不会误捕获。
- 普通 for 建立编译器同构的外层改名变量和循环体内层变量；for-in 建立内部迭代器和源码循环变量。合成绑定只记录在元数据中，不修改 AST。
- 默认参数表达式在外层声明作用域解析，不求值，也不提前绑定到调用参数 slot。
- 赋值左值单独解析，避免把 `isLocal == false` 的赋值目标误当作成员键。
- 显式遍历 return、throw、assert 描述、解构初始化器和 struct 字段值，避免遗漏闭包引用。
- 类、struct、namespace、导入成员和未解析标识符保守回退；删除操作保留引用元数据，同时加入 `dynamicOperations`。
- 类型表达式不作为运行时变量引用解析。

### 元数据验收

11 项专项测试全部通过，覆盖：

- 参数与局部 slot、块级遮蔽及声明身份一致性。
- 嵌套捕获、同名参数、模块与局部递归。
- 默认参数的外层引用。
- for/for-in 合成绑定和真实循环捕获。
- 类成员、未解析标识符、删除操作和动态回退。
- return、throw、assert、struct 闭包，以及 namespace、import、struct 和 external 声明。

### 回归验证

- 全量 `dart test` 为 477 项全部通过，其中阶段零语义矩阵 11 项、阶段一解析器测试 11 项。
- 三个新增实现或测试文件执行 `dart analyze` 无问题，格式检查通过。
- JIT/AOT 的所有既有和新增基准均实际执行，校验值正确，`foldable`/`dynamic` 字节码仍分别为 880/1065 字节。
- 解析器未接入执行管线，因此本阶段测量只用于回归，不宣称性能收益，也不重新测量分配量。

关键回归中位数如下，单位均为微秒；与阶段零的小幅差异按机器噪声处理：

| 场景 | JIT | AOT |
| --- | ---: | ---: |
| fib | 2289556 | 2833326 |
| local | 173335 | 210280 |
| uncaptured_closure | 127517 | 152999 |
| captured_variable | 149093 | 186462 |
| dynamic_fallback | 124594 | 146182 |
| foldable | 386870 | 476011 |
| dynamic | 527665 | 643201 |

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

- `packages/hetu_script/lib/optimization/`
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
