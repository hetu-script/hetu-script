# 代码的模块化

## 代码文件的导入

代码文件可以使用 import 声明导入其他代码文件，解释器会提前将代码导入的其他文件解释并保存在内存中。

## 单一字节码模块

可以使用 compile() 方法将一段代码编译成一个单一字节码文件。在编译时，编译器会自动将代码中使用 **import** 语句导入的所有其他代码文件一并编译，这样在再分发时只需要发布单一的字节码模块即可。

## 资源空间

资源空间（HTResourceContext）是一个抽象接口，指编译器获取代码文件的辅助类。默认的资源空间的实现是 **HTOverlayContext**。这个实现不会自动读取任何资源。用户需要提前手动添加代码文件，才可以让 import 语句生效。

## 资源类型

资源类型（ResourceType）决定了解释器如何看待代码以及如何看待 import 语句引入的文件。在解释器的 **eval()** 方法中包含这个参数。

- 当省略掉 eval() 方法的 **ResourceType type** 参数时，解释器会以字面量的形式解释字符串（**ResourceType.hetuLiteralCode**）。这种类型的代码不会生成自己的命名空间，而是直接使用全局命名空间。

- 当 eval() 方法的代码类型参数为 **ResourceType.hetuScript** 时，解释器会使用类似 Javascript, Python 和 Lua 那样的形式来解释。除了声明语句之外，代码中可以直接执行表达式语句，例如在代码顶层直接调用某个函数。这种类型的代码会使用单独的命名空间。执行这种代码的效果类似于执行一个匿名函数。代码中的变量的初始化值会被立即运算。代码按照书写的顺序执行。

- 当 eval() 方法的代码类型参数为 **ResourceType.hetuModule** 时，解释器会使用类似 C++, Java 和 Dart 那样的 APP 的形式来解释。代码中只允许包含导入导出语句，以及声明语句。代码中的变量的初始化值在调用时才会被计算出来。代码的执行顺序也并不一定是书写顺序。可以通过传入 invoke 参数来立即调用一个函数。但不要求这个函数一定是 'main' 函数。

对于解释器的 **evalFile()** 方法，代码文件类型将以文件名后缀作为判断基准：'\*.hts' 对应了 **ResourceType.hetuScript**，而 '\*.ht' 对应了 **ResourceType.hetuModule**。

## 导入字节码文件

一个已经编译成了[字节码文件](../command_line_tool/readme.md#compile)的模块也可以被导入。但只能以整个模块导入，其作为入口代码的文件指定了你可以导入的内容。使用这种单一字节码文件可以提交一些效率，因为这样解释器无需进行 parse, analyze, compile 的过程。

在脚本代码文件中导入前，你需要通过解释器上的 **loadBytecode()** 方法来载入这个文件。下面是一个例子：

```dart
import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'example/script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final binaryFile = File('example/script/module.out');
  final bytes = binaryFile.readAsBytesSync();
  hetu.loadBytecode(bytes: bytes, module: 'calculate');
  hetu.evalFile('import_binary_module.hts');
}
```

然后你可以在代码中使用 import 加上 'module:' 开头的路径来导入它。注意，出于错误检查的目的，此时你**必须**为引入的 module 提供一个命名空间别名。

```dart
import 'module:calculate' as calculate;

final result = calculate.calculate()
```

## 导入 JSON 文件

和 Javascript 一样，河图中的对象字面量语法和 JSON 完全兼容，因此你可以直接导入一个 JSON 文件，而无需进行任何类型转换。

河图提供的 ResourceContext 会默认载入 json 和 json5 类型的文件作为代码文件。

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'example/script');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.eval('''
    import 'values.json' as json
    print(json.name) // use json value like a struct
  ''');
}
```

注意，json 资源文件并非代码文件，没有命名空间，因此在导入时必须指定一个别名才可以使用。
