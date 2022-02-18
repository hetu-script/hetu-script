# Dart 中的解释器 API

## Interpreter

The most common class you will be using is the Interpreter, it is named as 'Hetu' in this library.

### init()

A convenient way to load some shared modules all together when Hetu initted.

```dart
void init({
  Map<String, String> includes = const {},
  Map<String, Function> externalFunctions = const {},
  Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
  List<HTExternalClass> externalClasses = const ****,
})
```

- **preincludes**: Hetu source in String literal form. You can also use **eval** methods to load them later.

- **externalFunctions**: Dart functions to be binded with a external function declaration in Hetu. You can also use **bindExternalFunction** methods to load them later.

- **HTExternalFunctionTypedef**: Dart typedefs to be used when a Hetu function want to be converted to a Dart function when evaluated. You can also use **bindExternalFunctionType** methods to load them later.

- **HTExternalClass**: Dart class bindings to be used by Hetu to get class definitions. You can also use **bindExternalClass** methods to load them later.

### eval()

To parse, analyze, compile and load a Hetu source from a String literal.

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

- **content**: Hetu source as String literal.
- **fileName**: The name of this source, it will be used when other source try to import from it.
- **moduleName**: The name of the compiled bytecode module.
- **globallyImport**: Whether you want the content of this source is visible to **global** namespace. It's a quicker way to let other modules to use without import statement.
- **type**: How the interpreter evaluate this source. For more information, check [**source type**](../../guide/package/readme.md#resource-type).
- **isStrictMode**: If strict mode is true, the condition expression used by if/while/do/ternery must be a boolean value. Otherwise there will be inexplicit type conversion.
- **invokeFunc**: Invoke a function immediately after evaluation. The function's name and parameter can be of any form. The arguments of this function call are provided by **positionalArgs** and **namedArgs**. You can also use the separate method **invoke** to do the same thing.

### compile(), loadBytecode()

These methods is useful if you want a more efficient runtime for the script. You can compile a source into bytecode. And run it at another time so that the interpreter will skip the parsing, analyzing and compiling process.

If you would like to compile and store the result as physical files. You can check [**command line tool**](../../guide/command_line_tool/readme.md#compile) in the hetu_script_dev_tools package.

## Invoke a method on Hetu object

Besides the **invoke** method on interpreter, you can also use the same named methods on **HTClass** and **HTInstance** and **call** on **HTFunction**, if you have those object passed from script into the Dart.

## ResourceContext

If you installed 'hetu_script_dev_tools' or 'hetu_script_flutter', they will handle the source context for you so you won't need to add the source file into the context manually. However if you cannot use these packages(for example if your code are running on web browser), you can use methods below on **HTOverlayContext** to manage sources.

```dart
void addResource(String fullName, HTSource resource)

void removeResource(String fullName)

void updateResource(String fullName, HTSource resource)
```
