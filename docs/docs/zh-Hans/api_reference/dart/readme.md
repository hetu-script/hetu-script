# Dart API 参考

## 解释器

使用河图脚本库的时候，在 Dart 中的最常用类是解释器（interpreter）。它的名字就叫做 **Hetu**。下面是一些解释器上的常用方法。

### init()

这个方法会初始化河图脚本内置的一些 Dart 类的绑定。用户也可以向这个方法传入参数来同时初始化一些自定义绑定。

```dart
void init({
  Map<String, String> includes = const {},
  Map<String, Function> externalFunctions = const {},
  Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
  List<HTExternalClass> externalClasses = const ****,
})
```

- **preincludes**: 载入一些以 Dart 字符串形式保存的代码文件。效果等同于在 **init()** 执行完毕后，手动调用 **eval()**。

- **externalFunctions**: 载入一些 Dart 函数，用以在脚本中调用。效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalFunction()**.

- **HTExternalFunctionTypedef**: 载入一些 Dart 的函数定义，以及对应的解绑函数。之后可以便捷的将一个脚本函数解析为 Dart 函数，以用于 Dart 的对象的构造函数等需要 Dart Lambda 的场合。。效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalFunctionType**.

- **HTExternalClass**: 载入一些 Dart 类的绑定定义。之后可以在脚本中直接获得一个 Dart 对象，或者调用某个 Dart 对象的函数。 效果等同于在 **init()** 执行完毕后，手动调用 **bindExternalClass**.

### eval()

解释一个字符串形式的代码文件。使用这个方法会在内部经历完整的 parse, analyze, compile 的过程，最终以字节码形式保存在内存中。后续调用以字节码形式执行。

```dart
dynamic eval(String content,
    {String? fileName,
    String? moduleName,
    bool globallyImport = false,
    ResourceType type = ResourceType.hetuLiteralCode,
    bool isStrictMode = false,
    String? invokeFunc,
    List<dynamic> positionalArgs = const ****,
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const ****,
    bool errorHandled = false})
```

- **content**: Dart 字符串形式的代码文件内容。
- **fileName**: 文件名。如果其他代码文件使用了 import，将会参考这个名字。如果忽略，将会以字符串的头部内容加上 Hash 生成。
- **moduleName**: 模块名。整个代码文件编译后的字节码整体称作一个模块。
- **globallyImport**: 是否将这个模块的内容直接导入到全局命名空间。这样做可以让其他模块以后无需导入即可使用这个代码文件的内容。
- **type**: [**代码文件类型**](../../guide/package/README.md#资源类型)。决定了解释器的行为模式
- **isStrictMode**: 严格模式。在严格模式下，对于流程控制和逻辑和、或等场合，不会进行布尔值的隐式转换。
- **invokeFunc**: 在解析完毕后，直接执行这个代码文件中的一个函数。函数的参数用 **positionalArgs** 和 **namedArgs** 传递。效果等同于在 **eval()** 执行过后，再手动调用 **invoke()**。

### compile(), loadBytecode()

这一对方法可以用于需要更高运行效率的场合。**compile()** 将一个代码文件编码为字节码。随后可以在另外的场合获取这段字节码然后调用 **loadBytecode()** 执行。在执行时，将无需再进行 parse, analyze, compile 的过程。

可以参考 hetu_script_dev_tools 包提供的[**命令行工具**](../../guide/command_line_tool/readme.md#compile)中附带的编译功能。

### invoke()

在解释器对象上用这个方法来调用某个代码文件中定义的函数。类似的，也有一些其他的调用存在与脚本的 **HTClass**，**HTInstance**, **HTFunction** 等对象上。如果你讲这些脚本中的对象直接传回了 Dart 代码，就可以使用这个接口来调用函数。

## 代码空间

**HTResourceContext** 是解释器保存和管理代码文件的抽象工具类。如果你安装了 **hetu_script_dev_tools** 或者 **hetu_script_flutter**，将会有各自对应的代码空间类的具体实现来管理你磁盘上，或者 Flutter 程序中的资源文件。默认情况下的代码空间实现是 **HTOverlayContext** ，这个实现不会主动读取文件，而需要通过下面这些接口来手动保存和更新代码文件：

```dart
void addResource(String fullName, HTSource resource)

void removeResource(String fullName)

void updateResource(String fullName, HTSource resource)
```
