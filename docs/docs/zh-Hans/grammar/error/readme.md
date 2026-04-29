# 错误和异常的处理

可以在脚本中使用 **assert** 或 **throw** 关键字手动抛出异常。

## assert

```dart
assert(1 > 5)
```

当括号中的表达式值为 false 时，将抛出 `AssertionError`。错误消息将包含括号中的源代码文本，以帮助了解失败原因。

表达式的值必须是 boolean 类型。

可以通过在 Hetu 配置中设置 `removeAssertion: true` 来从编译的字节码中移除断言。

## throw

```dart
var i = 42
throw 'i is ${i}!'
```

throw 语句用来抛出一个对象。错误消息将包含 throw 后面表达式的 toString() 值。

throw 语句后必须显式提供一个表达式，但这个表达式的值可以是 null。

## 常见运行时错误

当配置中启用 `processError` 时，解释器会报告带有源码位置信息（文件、行、列）的错误。常见的运行时错误包括：

| 错误码 | 原因 |
|--------|------|
| `undefined` | 访问尚未声明的变量或标识符 |
| `notInitialized` | 在首次赋值前访问 `late` 变量 |
| `immutable` | 重新给 `final`、`const` 或 `late` 变量赋值 |
| `arity` | 调用函数时提供了错误数量的位置参数 |
| `argType` | 传递了错误类型的参数（启用运行时类型检查时） |
| `notCallable` | 尝试调用非函数的值 |
| `undefinedMember` | 访问类实例上不存在的成员 |
| `outOfRange` | 列表索引越界 |
| `typeCast` | 使用 `as` 进行无效类型转换 |
| `circleInit` | 变量初始化引用自身 |
| `notSpreadableObj` | 展开不可迭代或非结构体的值 |
| `callNullObject` | 尝试对 `null` 调用方法 |
| `subGetKey` | 无效的下标键类型 |

## 错误处理器配置

`InterpreterConfig` 提供了多个控制错误输出的选项：

- **processError**（默认：`true`）：启用时，错误在重新抛出前会附加源文件、行和列信息。
- **showHetuStackTrace**（默认：`false`）：在错误输出中包含河图脚本调用栈。
- **showDartStackTrace**（默认：`false`）：在错误输出中包含 Dart 宿主调用栈。
- **stackTraceDisplayCountLimit**（默认：`5`）：显示的栈帧最大数量。

## 错误处理

目前不能在脚本中处理异常（不支持 `try...catch`），建议在 Dart 代码中进行处理。
