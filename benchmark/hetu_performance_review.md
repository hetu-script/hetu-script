# Hetu Script 性能测试与 CPU Profile 报告

## 1. 测试目的

本报告用于回答两个问题：

1. 哪些类型的 Hetu 脚本操作相对较慢？
2. 原始递归 `fib(30)` 的主要耗时集中在哪些 Dart 实现路径？

测试不修改 Hetu 源码，也不预设必须通过更换实现语言来解决问题。分类基准和 CPU profile 分开进行，避免把 JIT 与 AOT 的绝对耗时直接混用。

## 2. 测试对象与环境

- 操作系统：Windows。
- Dart SDK：3.13.2 stable，Windows x64。
- 黑盒基准：当前安装的 `hetu_script_dev_tools` 0.2.0 命令行程序，即安装版 AOT `hetu.exe`。
- CPU profile：从 `D:\_dev\hetu-script` 工作区通过 `dart run --observe` 启动，属于 Dart JIT 快照。
- 检查时源码 HEAD：`4c7c2fa26e6299e7ca667b420266cbd4d51cd659`。
- 检查时工作区已有其他 agent 的未提交修改，包括 `interpreter.dart` 等文件。因此源码 profile 只代表当时工作区状态，不代表一个干净提交。

所有新增测试文件均位于 `D:\_dev\idea`：

- `benchmark.hts`：分类黑盒性能基准。
- `profile_fib.hts`：连续执行 5 次原始递归 `fib(30)`，为 CPU profiling 提供足够采样时间。
- `vm_cpu_samples.dart`：通过 Dart VM service 获取 CPU samples、计算 inclusive/exclusive 样本占比，并在 `PauseExit` 状态下恢复 isolate 退出。
- `fib.hts`：单次原始递归 `fib(30)` 基准。

## 3. 测试方法

### 3.1 分类基准

以纯 `while` 循环为基线，分别增加以下操作：

- 局部整数算术。
- 多个局部变量读写。
- 全局变量读写。
- 空函数和带参数/返回值的普通函数调用。
- 闭包调用。
- List 下标读写。
- 动态对象成员读写。
- 实例方法调用。
- 类实例构造。
- 字符串插值。

每个场景使用 `console.time()` / `console.timeEnd()` 测量脚本执行区间，不包含命令行启动、源码加载和编译。共运行 4 轮，报告中使用近似中位数。各场景均返回校验值，避免只执行无意义代码或执行错误分支。

### 3.2 fib 基准

实现为无缓存原始递归：

```text
fib(n) = n                         n <= 1
fib(n) = fib(n - 1) + fib(n - 2)   n > 1
```

`fib(30) = 832040`，每次执行约有 2,692,537 次脚本函数调用。该场景主要压力来自函数调用、局部变量、比较、减法、加法、命名空间查找和字节码分派。

### 3.3 CPU samples

通过 Dart VM service 的 `getCpuSamples` 获取样本，分别统计：

- exclusive：样本栈顶位于该函数的比例，近似函数自身耗时。
- inclusive：样本栈中包含该函数的比例，包含其子调用。

不同 inclusive 指标存在调用链重叠，不能相加。线程等待函数 `ZwWaitForAlertByThreadId` 被排除在热点判断之外。

## 4. 分类基准结果

以下数据来自安装版 AOT `hetu.exe`，4 轮结果的近似中位数：

| 场景 | 迭代次数 | 总耗时 | 每次迭代 | 校验结果 |
|---|---:|---:|---:|---|
| 纯 while 循环 | 200,000 | 103 ms | 0.51 μs | 200000 |
| 局部整数加法 | 200,000 | 142 ms | 0.71 μs | 600000 |
| 多个局部变量读写 | 100,000 | 121 ms | 1.21 μs | 300003 |
| 全局变量读写 | 100,000 | 130 ms | 1.30 μs | 100000 |
| 空函数调用 | 200,000 | 240 ms | 1.20 μs | 200000 |
| 带参数和返回值的函数调用 | 200,000 | 280 ms | 1.40 μs | 200000 |
| 闭包调用 | 100,000 | 163 ms | 1.63 μs | 100000 |
| List 下标读写 | 100,000 | 135 ms | 1.35 μs | 100000 |
| 动态对象成员读写 | 100,000 | 210 ms | 2.10 μs | 100000 |
| 实例方法调用 | 100,000 | 335 ms | 3.35 μs | 100000 |
| 创建类实例 | 50,000 | 510 ms | 10.2 μs | 49999 |
| 字符串插值 | 50,000 | 92 ms | 1.84 μs | `prefix-49999-世界` |

### 4.1 分类结论

- 类实例构造是已测场景中单次成本最高的操作，约为纯循环的 20 倍。
- 实例方法调用和动态成员访问也具有明显额外成本。
- 普通函数调用成本明显高于纯循环，是 fib 的直接相关场景。
- 局部变量、List 下标和字符串插值存在解释器开销，但没有表现出类似对象构造的异常高成本。
- 这些是每轮完整循环的成本，不是单个字节码指令的独立成本。比较时应使用相同迭代规模或每次迭代列。

## 5. fib 结果

安装版 AOT `hetu.exe`：

- 单次测量：3,919 ms，结果 832040。
- 连续 5 次：总计 21,081 ms，平均 4,216.2 ms，结果 832040。
- 按 3,919 ms 估算，每次脚本递归调用约 1.45 μs；按 4,216.2 ms 估算约 1.57 μs。

该区间与“带参数和返回值的普通函数调用”每次迭代约 1.40 μs 的黑盒结果相近。由此可将 fib 的首要调查方向放在普通函数调用及其执行路径，而不是字符串、对象构造或 List 下标。

源码 JIT profile 进程的 5 次 fib 平均值分别约为 2,791.2 ms 和 2,851.8 ms。它们仅用于提供足够 profiling 时间，不能与上述 AOT 数字直接计算提速或回退比例。

## 6. CPU profile 结果

第一轮有效采样约 1,378 个样本，主要热点如下：

| Dart 函数 | Exclusive | Inclusive |
|---|---:|---:|
| `HTInterpreter._execute` | 11.8% | 84.7% |
| `BytecodeReader.readUint16` | 9.2% | 9.2% |
| `BytecodeReader.read` | 5.3% | 5.3% |
| `HTFunction._call` | 4.8% | 84.6% |
| `HTInterpreter._call` | 2.4% | 84.6% |
| `HTInterpreter._pushStack` | 1.3% | 9.9% |
| `HTStackFrame.push` | 2.4% | 8.3% |
| `HTStackFrame.pop` | 2.2% | 4.8% |
| `HTNamespace.memberGet` | 2.2% | 4.1% |
| `HTCallScope` 构造函数 | 1.9% | 3.3% |

其他反复出现的热点包括：

- `_GrowableList.add`、`removeLast`、`last`。
- `_GrowableList._growToNextCapacity`、`_shrink` 和数据分配。
- Map literal 创建、entries 获取及迭代器移动。
- `HTInterpreter.execute`、`stack`、`setContext` 和 `_createStackFrame`。

第二轮约 1,000 个样本再次指向字节码读取、函数调用、操作数栈、命名空间查找和调用作用域创建。由于 Dart 优化、采样和暂停退出等因素，两轮单个函数的 exclusive 比例有波动，应优先看一致出现的热点组，而不是追求小数点级复现。

### 6.1 profile 结论

fib 的热点不是单一慢指令，而是以下成本在约 269 万次递归调用中反复累积：

1. 调用分派和参数处理。
2. 调用作用域及调用帧维护。
3. 操作数栈 List 的添加、删除、扩容和收缩。
4. 字节码与操作数读取。
5. 递归函数名等命名空间成员查找。

这证明仍有明确的实现层优化调查方向，不能把与 CPython 的差距全部视为“运行在 Dart VM 上”的固定成本。具体可提速多少，需要每项改动独立测量后才能确定。

## 7. 源码对应位置

以下位置与 profile 热点或黑盒结果相符，供审核时定位，不表示已经证明每一行都是首要瓶颈：

- `packages/hetu_script/lib/interpreter/interpreter.dart:1330`：主 `_execute` 字节码分派循环。
- `packages/hetu_script/lib/interpreter/interpreter.dart:2221`：`OpCode.call` 处理。
- `packages/hetu_script/lib/interpreter/interpreter.dart:2265`：每次调用创建 `namedArgs` Map，即使没有命名参数。
- `packages/hetu_script/lib/interpreter/interpreter.dart:2279`：每次调用创建位置参数 List。
- `packages/hetu_script/lib/value/function/function.dart:349`：`HTFunction._call`。
- `packages/hetu_script/lib/value/function/function.dart:423`：普通函数调用创建 `HTCallScope`。
- `packages/hetu_script/lib/value/call_scope/call_scope.dart:28`：调用作用域创建 slots、mutable、initialized 等多个 List。
- `packages/hetu_script/lib/interpreter/interpreter.dart:163`：调用帧使用可增长 `operandStack`。
- `packages/hetu_script/lib/value/instance/instance.dart:59`：构造实例时遍历并克隆类成员声明，是对象构造高成本的候选原因。

由于工作区当时有其他 agent 的未提交修改，审核时应以相同工作区状态重新核对行号和实现。

## 8. 建议的优化调查顺序

### 优先级 1：普通函数调用路径

检查空命名参数 Map、位置参数 List、参数绑定遍历、上下文和调用帧创建是否可以减少或复用。任何缓存或复用都必须验证闭包、默认参数、命名参数、可变参数、spread、外部绑定、异步和递归重入语义。

### 优先级 2：操作数栈与调用帧

结合 allocation profile 检查 List 扩容、收缩和临时分配。不要仅凭 `_GrowableList` 的热点就替换数据结构，应先确认容量变化模式和实际分配来源。

### 优先级 3：字节码读取与命名空间查找

`read` 和 `readUint16` 合计占比较明显。可以调查读取路径和操作数解码，但需要保持模块偏移、端序和缓存生命周期正确。命名空间缓存必须有清晰的失效规则，不能破坏全局变量重定义和模块隔离。

### 独立方向：对象构造和方法调用

对象构造在黑盒测试中最慢，但尚未单独抓 CPU profile。建议先增加对象构造专项 profile，再决定是否优化成员声明克隆、实例命名空间或成员解析，不要把它与 fib 优化混为一项改动。

## 9. 复现步骤

在支持 `hetu` 命令的 Windows 终端中：

```bash
hetu run D:\_dev\idea\benchmark.hts
hetu run D:\_dev\idea\fib.hts
hetu run D:\_dev\idea\profile_fib.hts
```

从 Hetu 源码目录启动 JIT profiling：

```bash
cd D:\_dev\hetu-script
dart run --observe=8888 packages/hetu_script_dev_tools/bin/cli_tool.dart run D:/_dev/idea/profile_fib.hts
```

然后可选择：

1. 运行 `dart devtools`，连接终端输出的完整 VM service URI，在 CPU Profiler 中录制并查看 Call Tree/Bottom Up。
2. 使用随附采样工具：

```bash
dart D:\_dev\idea\vm_cpu_samples.dart "ws://127.0.0.1:8888/<token>/ws"
```

如果进程停在 `PauseExit`，采样工具会发送 `resume`，使 isolate 正常退出。若端口被占用，应更换端口或正常结束之前由本次 profiling 启动的进程。

## 10. 结论边界与审核建议

- 分类基准只覆盖所列微基准，不能据此宣称 Hetu 所有程序都比其他语言慢固定倍数。
- fib 是函数调用密集型基准，不能代表 I/O、外部绑定、集合处理、字符串或真实 Flutter 游戏性能。
- JIT profile 可用于定位热点，但不能把 JIT 的提速比例直接外推到 Flutter AOT。
- 对象构造的高成本已由黑盒测量确认，但其具体 Dart 热点尚需专项 profile。
- 另一个 agent 正在修改源码，后续结果必须在明确基线、相同脚本和相同运行模式下复测。
- 建议每项优化独立执行功能测试、JIT/AOT 基准和分配检查，记录保留或撤回依据，避免多个改动同时合入后无法归因。

总体结论：fib 的主要慢点是普通函数调用及其配套执行机制；对象构造、方法调用和动态成员访问是另外值得调查的高成本场景。当前数据支持继续在 Dart 实现内做有针对性的 profiling 和优化，不支持仅凭 fib 差距就推倒重写解释器。
