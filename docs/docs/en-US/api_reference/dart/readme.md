# API for use in Dart

## Hetu helper class

Hetu is a wrapper class that integreted sourceContext, lexicon, parser, bundler, analyzer, compiler and interpreter's default implementation. For normal users, you can just create an instance of Hetu, and use the method on it.

In fact, Hetu will call method with same name on compiler or interpreter separately.

### init()

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

A convenient way to load some shared modules all together when Hetu initted.

- **externalFunctions**: Dart functions to be binded with a external function declaration in Hetu. You can also use **bindExternalFunction** methods to load them later.

- **HTExternalFunctionTypedef**: Dart typedefs to be used when a Hetu function want to be converted to a Dart function when evaluated. You can also use **bindExternalFunctionType** methods to load them later.

- **HTExternalClass**: Dart class bindings to be used by Hetu to get class definitions. You can also use **bindExternalClass** methods to load them later.

### eval(), evalFile()

To parse, analyze, compile and load a Hetu source from a String literal. The script functions will be compiled into bytecode form, and won't need to be parsed again on later execution.

```dart
dynamic eval(String content,
    {String? file,
    String? module,
    bool globallyImport = false,
    HTResourceType type = HTResourceType.hetuLiteralCode,
    String? inovaction,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const []})
```

- **content**: Hetu source as String literal.
- **file**: The name of this source, it will be used when other source try to import from it.
- **module**: The name of the compiled bytecode module.
- **globallyImport**: Whether you want the content of this source is visible to **global** namespace. It's a quicker way to let other modules to use without import statement.
- **type**: How the interpreter evaluate this source. For more information, check [**source type**](../../guide/package/readme.md#resource-type).
- **inovaction**: Invoke a function immediately after evaluation. The function's name and parameter can be of any form. The arguments of this function call are provided by **positionalArgs** and **namedArgs**. You can also use the separate method **invoke** to do the same thing.

### compile(), compileFile(), loadBytecode()

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
