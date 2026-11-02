# 函数调用性能优化计划

## 背景与目标

当前函数调用的主要可疑成本是每次调用创建的命名空间、调用帧、参数集合和调用栈字符串，以及外部对象成员访问时重复创建的包装器。现有 `fib(30)` 在本机 Dart JIT 下的三次脚本执行耗时约为 9.55、9.44、8.86 秒，但该结果不能代表 Flutter AOT，也不能单独说明某个热点所占的比例。

本计划的目标是：

- 建立可重复、可比较的性能测试，分别测量纯脚本调用和 Dart 绑定调用。
- 优先实施不改变语言语义和公开绑定 API 的优化。
- 每个阶段独立测量，保留有明确收益的改动，避免仅凭推测增加复杂度。
- 最终仍要在真实 Flutter/Flame 游戏的 profile 模式中确认收益。

## 本次实施结果（2026-11-02）

本次只执行了局部、低风险的优化，没有调整公开 API、调用帧模型、字节码格式或异步调度：

- 新增 `test/performance/function_call.dart` 和 `test/performance/binding_call.dart`。
- 减少 `OpCode.call` 的零参数中间集合、参数复制和 `insert(0, ...)`；无 spread 时直接复用可变参数列表。
- 原始 Dart 函数没有命名参数时不再创建 `Map<Symbol, dynamic>`。
- 关闭 `showHetuStackTrace` 时不再记录和弹出脚本调用栈。
- 脚本参数绑定改为单次 entries 遍历，保持省略参数和 variadic 的索引语义。
- `HTStackFrame` 的 loops/anchors，以及命名空间的 fullName 和部分辅助集合改为延迟初始化。
- 新增 spread 参数顺序和外部绑定参数集合可修改性的回归测试。

Dart JIT 下各场景五次测量的中位数如下。提升比例按 `(基线 - 优化后) / 基线` 计算：

| 场景 | 基线 | 优化后 | 耗时下降 |
| --- | ---: | ---: | ---: |
| empty | 671.731 ms | 569.537 ms | 15.2% |
| identity | 766.427 ms | 588.786 ms | 23.2% |
| closure | 476.298 ms | 409.368 ms | 14.1% |
| named | 537.252 ms | 472.121 ms | 12.1% |
| variadic | 2058.749 ms | 1820.231 ms | 11.6% |
| spread | 611.059 ms | 532.075 ms | 12.9% |
| stack_trace | 768.363 ms | 637.731 ms | 17.0% |
| external_function | 351.203 ms | 284.627 ms | 19.0% |
| raw_function | 436.715 ms | 363.556 ms | 16.8% |
| external_method | 429.396 ms | 368.161 ms | 14.3% |
| external_property | 379.299 ms | 367.421 ms | 3.1%，视为噪声 |
| dart_to_script | 155.903 ms | 100.736 ms | 35.4% |
| nested_callback | 228.682 ms | 159.777 ms | 30.1% |

`fib(30)` 的改动前三次执行为 9.551、9.442、8.859 秒，改动后一次为 6.923 秒；相对改动前中位数下降约 26.7%。`fib` 仍需在后续重复测量中确认稳定范围。

验证结果：全量 `dart test` 共 436 项通过；修改文件的 `dart analyze` 无问题；两个性能脚本均通过 AOT 编译和实际执行，校验值正确。AOT 没有记录改动前基线，因此不计算其提速比例。

本次没有实施结构化调用栈、预计算完整参数元数据、轻量调用作用域、外部对象缓存和固定 arity 适配器。这些仍按后续阶段处理，尤其不能在本次结果上推断大型改造一定产生相同比例的收益。

不在本计划初期实施：

- 使用 C/Rust 重写解释器。
- 改变 `async` 函数的调度语义。
- 同时重写编译器、字节码格式和运行时值系统。
- 为了达到预设提速倍数而接受正确性或 API 兼容性回退。

`plan_namespace_performance.md` 中的局部变量槽位、类型特化和内联缓存属于后续结构性优化，不作为第一阶段的依赖。

## 一、建立性能基准

### 1. 保留现有递归基准

保留 `test/performance/fib.dart` 的初始版本作为对照，不在记录第一轮基线前修改它。它主要反映递归、局部变量读取和整数运算的综合成本，不能代表所有函数调用。

### 2. 新增纯脚本调用基准

新增 `test/performance/function_call.dart`，沿用现有性能脚本的独立 `main()` 形式，不引入新的 benchmark 依赖，也不命名为 `_test.dart`，避免被 `dart test` 自动执行。

包含以下场景：

- `empty`：循环调用无参数、无返回值的函数，测量基础调用成本。
- `identity`：循环调用单参数函数并累计返回值，测量参数和返回值路径。
- `closure`：调用捕获外层变量的函数，测量闭包调用及捕获变量读取。
- `named`：调用带命名参数和默认值的函数，覆盖命名参数 map 组装。
- `variadic`：调用可变参数函数，覆盖参数展开和可变参数列表。
- `spread`：循环调用带 spread 参数的函数，覆盖参数展开路径。

实现约束：

- 每个脚本只编译、初始化一次，计时只覆盖执行，不包含词法分析、编译和模块加载。
- 在脚本内使用循环执行 N 次目标调用，Dart 侧只启动一次 `Stopwatch`，避免每次 `invoke` 的宿主调用干扰结果。
- 返回并打印校验值，确认每次运行执行了相同工作，且结果正确。
- `printPerformanceStatistics` 保持关闭，不在计时代码中打印日志。
- 默认使用 `showHetuStackTrace: false`；为调用栈优化增加独立的 `stack_trace` 场景，分别测量开启和关闭时的成本。
- 命令行可选择单个场景和迭代次数；默认运行全部场景。迭代次数应使单个场景测量达到数百毫秒以上，避免只测到计时误差。

### 3. 新增绑定调用基准

新增 `test/performance/binding_call.dart`，包含：

- `external_function`：脚本循环调用 `HTExternalFunction`。
- `raw_function`：脚本循环调用原始 Dart `Function`，覆盖 `Function.apply`。
- `external_method`：脚本循环调用 `HTExternalClass` 返回的实例方法。
- `external_property`：循环读取和写入外部对象属性，测量 `encapsulate` 和成员分发。
- `dart_to_script`：Dart 持有脚本函数并循环调用，测量 Dart 到脚本的调用。
- `nested_callback`：脚本调用 Dart，Dart 再调用脚本回调，测量双向嵌套调用。

外部对象使用简单的计数器或数据类，绑定本身只做极少工作，使测量主要反映运行时边界成本。属性读取不能缓存结果，方法返回值需要参与最终校验。

### 4. 测量方法

每个场景先预热，再至少测量 5 次，输出：

- 场景名、迭代次数和实际函数调用次数。
- 每次耗时、中位数和每次调用的近似耗时。
- 最终校验值。
- 配置项，尤其是是否开启脚本调用栈。

分别在以下模式记录结果：

```bash
# Dart VM/JIT，用于快速迭代
 dart run test/performance/fib.dart
 dart run test/performance/function_call.dart
 dart run test/performance/binding_call.dart

# Dart AOT，用于接近桌面和 Flutter release 的原生执行方式
 dart compile exe test/performance/function_call.dart -o .dart_tool/function_call.exe
 dart compile exe test/performance/binding_call.dart -o .dart_tool/binding_call.exe
 .dart_tool/function_call.exe
 .dart_tool/binding_call.exe
```

测量时保持相同 Dart SDK、机器和电源状态。JIT 与 AOT 结果分开比较，不直接混用。小于约 5% 的差异先视为可能的噪声；只有在重复运行中稳定出现的差异才用于决定保留改动。临时可执行文件和日志放在 `.dart_tool`，不提交。

在调用帧和外部包装优化前，再使用 Dart DevTools 的 CPU/内存分析确认分配热点。最终在游戏目标设备的 Flutter profile 模式下测量帧耗时，不以微基准替代真实场景。

## 二、分阶段实施

每个阶段独立修改、运行针对性测试并记录基准。若收益处于噪声范围内而代码明显变复杂，则不保留该阶段的可选优化。

### 阶段 1：减少 `OpCode.call` 参数组装分配

涉及：

- `packages/hetu_script/lib/interpreter/interpreter.dart`
- `packages/hetu_script/lib/value/function/function.dart`

执行内容：

1. 对零参数和零命名参数增加快速路径，避免创建无用的中间列表和 map。
2. 使用 `List.filled()` 和从后向前填充替代 `insert(0, stack.pop())`。
3. 无 spread 时减少 `posValues` 到 `posArgs` 的二次复制。
4. 外部实例调用需要构造参数列表时，使用定长填充替代扩展操作符。
5. 原始 Dart 函数没有命名参数时，不再创建空的 `Map<Symbol, dynamic>`。

兼容性约束：

- 脚本内部只读参数时可以使用共享空集合或定长列表。
- 当前外部绑定收到的是可修改的 `List`/`Map`。在不能确认绑定不会修改它们之前，不把共享常量集合或定长列表直接传给外部函数；必要时在外部边界恢复可变集合。
- 保持位置参数、命名参数、spread 和 variadic 的原有顺序。

验证：

- 运行 `function_call.dart` 的 `empty`、`identity`、`named`、`variadic`、`spread`。
- 运行 `binding_call.dart`，确认外部参数集合行为没有变化。
- 在 `test/interpreter/function_test.dart` 增加缺失的零参数、spread 和默认值组合用例。

### 阶段 2：降低调用栈记录成本并整理出栈逻辑

涉及：

- `packages/hetu_script/lib/value/function/function.dart`
- `packages/hetu_script/lib/interpreter/interpreter.dart`

执行内容：

1. `showHetuStackTrace == false` 时，不拼接调用栈字符串，也不执行无意义的列表压入和弹出。
2. 开启调用栈时，保存函数引用、文件和行列号等结构化信息，只在 `processError()` 需要输出时格式化字符串。
3. 统一正常返回、提前返回和异常路径的出栈逻辑，避免多处手动 `removeLast()`。
4. 检查异常路径当前帧在 `processError()` 前被移除的问题，确保错误堆栈包含实际抛出异常的函数。
5. 保持 `stackTraceDisplayCountLimit` 的截断方向和输出格式。

验证：

- 比较 `stack_trace` 场景开启和关闭配置的结果。
- 在解释器错误测试中覆盖递归错误、当前函数名、显示条数限制和关闭调用栈配置。
- 运行异步测试，确认 `FutureExecution` 恢复上下文后调用栈没有串扰。

### 阶段 3：减少参数声明的重复分析

涉及：

- `packages/hetu_script/lib/value/function/function.dart`
- `packages/hetu_script/lib/declaration/function/function_declaration.dart`

执行内容：

1. 先将参数绑定中的 `values.elementAt(i)` 和 `keys.elementAt(i)` 改为单次 entry 遍历，避免重复线性查找。
2. 若基准仍有明显参数绑定成本，在函数解析阶段预计算有序参数元数据：参数名、声明、是否命名、是否初始化字段、variadic 位置。
3. 脚本函数和外部函数复用同一套参数绑定元数据，减少两条路径的分歧。
4. 保留省略参数 `_`、默认值解析、构造函数字段初始化和 variadic 的现有语义，不提前执行有副作用的默认值表达式。

验证：

- 覆盖位置参数、可选参数、命名参数、默认值、`_`、variadic 和构造函数字段初始化。
- 比较 `identity`、`named`、`variadic` 和外部函数场景。

### 阶段 4：降低调用帧和调用闭包成本

涉及：

- `packages/hetu_script/lib/interpreter/interpreter.dart`
- `packages/hetu_script/lib/value/namespace/namespace.dart`
- `packages/hetu_script/lib/declaration/namespace/declaration_namespace.dart`
- `packages/hetu_script/lib/value/function/function.dart`

按风险从低到高执行：

1. 将 `HTStackFrame.loops` 和 `anchors` 改为首次使用时创建。
2. 将命名空间的 `fullName` 改为缓存的延迟计算；评估导入、导出等集合的延迟初始化，避免普通调用闭包支付完整模块命名空间的成本。
3. 引入轻量调用作用域，第一版仍使用符号名查找，但只保留局部符号、闭包引用和接收者信息，不携带模块导入导出设施。
4. 将 `HTNamespace` 保持用于模块、类等完整命名空间；不要直接在原类上堆叠更多调用帧特殊分支。
5. 测量 `HTContext` 的保存和恢复成本后，再决定是否减少上下文对象分配。

闭包约束：

- 被内部函数捕获的调用作用域必须在函数返回后继续存活。
- 不做全局调用帧池化。只有能够证明未逃逸时，才考虑复用，并单独测试。
- 闭包在循环中的身份和捕获行为必须与当前实现一致。

验证：

- 重点运行 `fib.dart`、`empty`、`identity`、`closure`。
- 运行 `test/interpreter/function_test.dart` 中闭包、循环闭包、递归和函数身份用例。
- 运行异步、类和 struct 测试，确认调用作用域与实例命名空间的交互不变。

### 阶段 5：减少外部对象包装和方法解析

涉及：

- `packages/hetu_script/lib/interpreter/interpreter.dart`
- `packages/hetu_script/lib/external/external_instance.dart`
- `packages/hetu_script/lib/value/function/function.dart`

执行内容：

1. 为外部类和成员 ID 缓存不变的函数声明查找结果，避免每次沿继承链重复解析。
2. 对普通 Dart/Flame 对象评估每个解释器持有 `Expando<HTExternalInstance>`，避免重复包装，同时不使用会阻止对象回收的全局强引用 map。
3. 数字、字符串、布尔值等不能直接套用普通对象的 `Expando` 方案，保留专门路径。
4. 属性值不做缓存，保证 `memberSet` 后读取到最新值。
5. 对动态返回不同函数对象的绑定，不默认缓存最终方法闭包；先缓存声明或解析元数据，保持每次获取外部函数的行为。
6. 同一个 `HTFunction` 重复转换为同一种外部回调类型时，评估缓存 Dart 回调包装，避免重复创建闭包。

验证：

- 比较 `external_method`、`external_property`、`dart_to_script`、`nested_callback`。
- 测试同一对象重复访问、不同对象不会发生接收者串用、属性修改立即可见、继承方法和动态绑定。
- 检查缓存不会使不同模块的同名外部类声明发生错误复用。

### 阶段 6：按测量结果处理原始 Dart `Function.apply`

只有在 `raw_function` 显示明确热点时执行：

1. 缓存命名参数使用的 `Symbol`。
2. 为常见的 0 至 N 个位置参数提供类型化适配器或直接调用路径。
3. 命名参数、可变参数和非常规签名继续回退到 `Function.apply`。
4. 不为极少调用的绑定增加大量生成代码。

保持 `HTExternalFunction` 和 `HTExternalMethod` 的现有公开签名，避免为了性能迫使游戏绑定全部改写。

## 三、后续可选结构性优化

完成上述阶段后，如果纯脚本调用仍占主要耗时，再从 `plan_namespace_performance.md` 中选择单独实施：

- 编译期为参数和局部变量分配槽位，使用索引读写代替字符串查找。
- 为高频变量或成员查找增加内联缓存，并处理声明变化时的缓存失效。
- 为整数、浮点数和无参数调用增加专用字节码。
- 对确定未捕获的调用帧做复用或逃逸分析。

这些改动会影响编译器、字节码兼容和闭包语义，应另设小阶段，不与前面的低风险优化混在同一次变更中。

## 四、测试与验收

每阶段先运行相关测试：

```bash
 dart test test/interpreter/function_test.dart
 dart test test/interpreter/binding_test.dart
 dart test test/interpreter/async_test.dart
 dart test test/binding/
```

涉及类、struct 或上下文恢复时再运行对应解释器测试。每阶段完成后运行：

```bash
 dart test
```

验收标准：

- 所有现有测试和新增回归测试通过，性能脚本校验值正确。
- 不改变脚本函数、闭包、默认值、命名参数、外部绑定和异步调用的可观察语义。
- 不修改公开绑定 API；若确需修改，单独讨论，不混入性能优化。
- 至少一个目标场景在重复测量中获得稳定收益，且其他调用场景没有无法解释的明显回退。
- 对分配相关优化，除耗时外还通过内存分析确认分配量下降。
- 最终在真实游戏中确认脚本耗时或帧时间改善；如果微基准变快而游戏没有收益，不继续扩大同类改造。

实施时在本计划中记录各阶段实际结果和放弃的可选项。若某项优化未产生稳定收益，优先保留更简单的原实现，并记录测量结论。
