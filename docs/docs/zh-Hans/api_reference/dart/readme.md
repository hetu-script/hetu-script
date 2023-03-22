# Dart API 参考

## Hetu 类

Hetu 是一个集合了多个不同的编程语言工具（sourceContext, lexicon, parser, bundler, analyzer, compiler and interpreter）的默认实现的工具类。

对于大部分普通用户，可以完全通过 Hetu 对象来使用脚本功能。Hetu 提供的函数接口，实际上是在调用 compiler 或者 interpreter 等底层的对象的方法。

### HetuConfig

HetuConfig 是一个配置环境的数据类。具体参数如下：

#### normalizeImportPath

默认值 `true`.

如果打开这个选项，sourceContext 将会记录某个代码文件的绝对路径，而非相对路径。并且你也可以在引入其他文件时使用相对路径。

例如，我们将 sourceContext 的根目录设置为 'scripts/'。然后在 'scripts/main/' 目录下的某个代码文件之内，我们使用如下代码引入一个上层文件：

```
// 'scripts/test/test.ht'
import '../main.ht'
```

此时 sourceContext 将会自动将相对路径 '../main.ht' 转化为硬盘上的绝对路径 'x:xxx/xxx/scripts/main.ht' 或者 flutter assets 目录中的路径：'scripts/main.ht'。然后使用绝对路径来获取该文件。

但此种方式并非适用于一切情况，例如你在开发时没有使用 HTFileSystemResourceContext 和 HTAssetResourceContext，而是完全手动管理代码文件。你可以关闭这个配置选项。此时所有的 import 语句都将会使用绝对路径。

#### explicitEndOfStatement

默认值 `false`.

如果打开这个选项，你必须在所有语句结束的位置手动写上 ';'，否则将会得到一个语法错误。

#### doStaticAnalysis (_experimental feature_)

默认值 `false`.

是否要在编译为字节码之前进行静态分析。

**注意！！！** 静态分析工具（HTAnalyzer）目前仍在开发中，因此除非你是想要为本项目贡献代码，否则 **不要** 打开这个选项。

#### computeConstantExpression (_experimental feature_)

默认值 `false`.

是否要在编译为字节码之前为常量表达式求值。

```dart
const b = 6
const c = 7
const a = b * c // 如果打开选项，这里的 a 也将会是常量，并且提前计算出来。
```

**注意！！！** 常量计算功能目前仍在开发中，因此除非你是想要为本项目贡献代码，否则 **不要** 打开这个选项。

#### removeLineInfo

默认值 `false`.

是否要在编译为字节码时去掉行列号信息。这样可以缩减字节码的大小。但如果出现错误时，可能难以找到具体问题所在的位置。

#### removeAssertion

默认值 `false`.

是否要在编译为字节码时去掉 assert 语句。这样可以缩减字节码的大小。

通常情况下， assert 语句所包含的表达式，在正确运行的程序中，永远为真。

不建议在可能出现预计之外的错误时使用 assert，例如文件或者网络处理时。

#### removeDocumentation

默认值 `false`.

是否要在编译为字节码时去掉文档注释。这样可以缩减字节码的大小。

文档注释指以 `///` 或者 `/** */` 形式书写的注释。

在运行时，你可以通过 `help()` 语句（可以通过 Hetu 类，也可以直接在脚本内部使用同名全局函数。）获取某个函数或者类的文档注释。

#### showDartStackTrace

默认值 `false`.

是否在遇到错误时显示 Dart 的堆栈信息。

#### showHetuStackTrace

默认值 `false`.

是否在遇到错误时显示河图函数调用的堆栈信息。

#### stackTraceDisplayCountLimit,

默认值 `5`.

堆栈信息显示时的最大数量。

#### processError

默认值 `true`.

决定脚本运行时是否在遇到错误时为错误补充一些信息，例如正在执行的行列号等。

#### allowVariableShadowing

默认值 `true`.

[参考](../../grammar/strict_mode/readme.md#variable-shadowing)

#### allowImplicitVariableDeclaration

默认值 `false`.

[参考](../../grammar/strict_mode/readme.md#implicit-variable-declaration)

#### allowImplicitNullToZeroConversion

默认值 `false`.

[参考](../../grammar/strict_mode/readme.md#zero-value)

#### allowImplicitEmptyValueToFalseConversion

默认值 `false`.

[参考](../../grammar/strict_mode/readme.md#truth-value)

#### checkTypeAnnotationAtRuntime

默认值 `false`.

如果打开这个选项，脚本解释器将会在运行时检查类型声明中的类型是否存在。

```dart
// 如果打开了这个选项，并且不存在 ClassA 对应的类型，这里将会报错
var a: ClassA;
```

#### resolveExternalFunctionsDynamically

默认值 `false`.

如果关闭这个选项，脚本中定义的外部函数将会 **记住** 所对应的外部 Dart 函数。之后就算你重新绑定，也不会改变了。

如果打开这个选项，将意味着每一次你调用脚本中外部函数时，都会向运行时查询该外部函数。这样会略微损失一些效率。

#### printPerformanceStatistics

默认值 `false`.

是否要在标准输出流中显示河图的运行效能信息。典型的输出如下，包含了解析、打包、编译、运行等步骤的耗时：

```
hetu: 36ms	to parse	[$script_e99c23d0: var globalVar = 0;...]
hetu: 2ms	to bundle	[$script_e99c23d0: var globalVar = 0;...]
hetu: 28ms	to compile	[$script_e99c23d0: var globalVar = 0;...]
hetu: 8ms	to load module	$script_e99c23d0: var globalVar = 0;... (compiled at 2023-03-22 06:53:35 UTC with hetu@0.4.3)
```

### sourceContext

如果你需要处理某个平台上的代码文件。你可以在 Hetu 对象的构造函数中传入一个 sourceContext 对象。

下面是一个处理本地磁盘上的代码文件的例子：

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  // you don't need to write the full path of the file here,
  // which means the file name without the `root` you specified in the sourceContext.
  // the sourceContext will know the full path and get it for you.
  final result = hetu.evalFile('import_test2.ht', invoke: 'main');
  print(result);
}
```

这样你就可以在代码中使用 import 语句，并正确的获取该外部代码文件了。

如果你安装了 **hetu_script_dev_tools** 或者 **hetu_script_flutter**，将会有各自对应的代码空间类的具体实现来管理你磁盘上，或者 Flutter 程序中的资源文件。

默认情况下的代码空间实现是 **HTOverlayContext** ，这个实现不会主动读取文件，而需要通过下面这些接口来手动保存和更新代码文件：

```dart
void addResource(String fullName, HTSource resource)

void removeResource(String fullName)

void updateResource(String fullName, HTSource resource)
```

[参考](../../guide/package/readme.md)

### Hetu 类提供的 api

#### init()

这个方法会初始化河图脚本内置的一些 Dart 类的绑定。用户也可以向这个方法传入参数来同时初始化一些自定义绑定。

```dart
void init({
  bool useDefaultModuleAndBinding = true,
  HTLocale? locale,
  Map<String, Function> externalFunctions = const {},
  Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
  List<HTExternalClass> externalClasses = const [],
  List<HTExternalTypeReflection> externalTypeReflections = const [],
})
```

- **useDefaultModuleAndBinding**: 如果这个参数为 true，河图将会载入一些默认的 Dart 对象的绑定。例如 print 函数，以及 Dart 中的字符串、数组的内置方法等等。如果这个参数为 false，你就只能将河图当作一个计算器来使用，进行一些纯表达式的计算，诸如 '5 \* 8 + 2' 之类。而不能使用 '(3.14).truncate()' 之类的方法。

- **externalFunctions**: 载入一些 Dart 函数，用以在脚本中调用。效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalFunction()**.

- **externalFunctionTypedef**: 载入一些 Dart 的函数定义，以及对应的解绑函数。之后可以便捷的将一个脚本函数解析为 Dart 函数，以用于 Dart 的对象的构造函数等需要 Dart Lambda 的场合。。效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalFunctionType**.

- **externalClasses**: 载入一些 Dart 类的绑定定义。之后可以在脚本中直接获得一个 Dart 对象，或者调用某个 Dart 对象的函数。 效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalClass**.

#### eval(), evalFile()

解释一个字符串形式的代码文件。使用这个方法会在内部经历完整的 parse, analyze, compile 的过程，最终以字节码形式保存在内存中。后续调用以字节码形式执行。

```dart
dynamic eval(String content,
    {String? file,
    String? module,
    bool globallyImport = false,
    HTResourceType type = HTResourceType.hetuLiteralCode,
    String? invoke,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const []})
```

- **content**: Dart 字符串形式的代码文件内容。
- **file**: 文件名。如果其他代码文件使用了 import，将会参考这个名字。如果忽略，将会以字符串的头部内容加上 Hash 生成。
- **module**: 模块名。整个代码文件编译后的字节码整体称作一个模块。
- **globallyImport**: 是否将这个模块的内容直接导入到全局命名空间。这样做可以让其他模块以后无需导入即可使用这个代码文件的内容。
- **type**: [**代码文件类型**](../../guide/package/README.md#资源类型)。决定了解释器的行为模式
- **invoke**: 在解析完毕后，直接执行这个代码文件中的一个函数。函数的参数用 **positionalArgs** 和 **namedArgs** 传递。效果等同于在 **eval()** 执行过后，再手动调用 **invoke()**。

#### compile(), compileFile(), loadBytecode()

这一对方法可以用于需要更高运行效率的场合。**compile()** 将一个代码文件编码为字节码。随后可以在另外的场合获取这段字节码然后调用 **loadBytecode()** 执行。在执行时，将无需再进行 parse, analyze, compile 的过程。

可以参考 hetu_script_dev_tools 包提供的[**命令行工具**](../../guide/command_line_tool/readme.md#compile)中附带的编译功能。

## Interact with the script, fetch(), assign(), invoke()

要在 Dart 代码中修改脚本内定义的变量，或者调用脚本函数，最简单的方法当然是直接使用 `eval`，例如：

```dart
hetu.eval('a = 5')
hetu.eval('someScriptFunction()')
```

但这种方法在你无法完全控制传入的字符串内容时具有隐患。例如你想要执行来自网络或者来自用户的代码时，有可能会发生一些对全局命名空间的污染，或者破坏。

因此我们提供了一些专用接口：

```dart
dynamic fetch(String id, {String? module})

void assign(String id, dynamic value, {String? module})

dynamic invoke(
    String func, {
    String? namespace,
    String? module,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
  })
```

**fetch** 和 **invoke** 可以用来定义或者获取变量。

**invoke** 可以用来调用某个脚本函数。

类似的，也有一些方法存在与脚本的 **HTClass**，**HTInstance**, **HTFunction** 等对象上。如果你将这些脚本中的对象直接传回了 Dart 代码，就可以使用这些对象上的 **invoke** 或者 **call** 来调用脚本函数。
