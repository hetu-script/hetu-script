# API for use in Dart

## Hetu helper class

The `Hetu` class is a wrapper class that integreted default implementation for sourceContext, lexicon, parser, bundler, analyzer, compiler and interpreter that you might need while using script.

For most circumstances, an instance of Hetu is all you need to deal with script. You can rely on the api provided by it. And Hetu will call method with same name on compiler or interpreter for you in the background.

### HetuConfig

This is a config data class used in the constructor of Hetu class.

#### normalizeImportPath

Defaults to `true`.

If this set to true, then the bundler will try to get the normalized path of the import key.

For example, if the root folder of the sourceContext is set to 'scripts/', and a script within the folder 'scripts/main/' declared a import statement:

```
// 'scripts/test/test.ht'
import '../main.ht'
```

The bundler will normalize the '../main.ht' path into some thing like 'scripts/main.ht', which is within the parent folder of test.ht, and directly under the scripts. This will help the sourceContext to fetch the correct file.

However, this is not always necessary. For example, if you neither use HTFileSystemResourceContext nor HTAssetResourceContext, you are manually control the sources. Then every path you are importing from will be the absolute path.

In this situation, you can set `normalizeImportPath` to false and use absolute path for every import statement.

#### explicitEndOfStatement

Defaults to `false`.

If this is set to `true`, then you would have syntactic error when you didn't write ';' at the end of statement.

#### doStaticAnalysis (_experimental feature_)

Defaults to `false`.

Wether analyze the code before compile to check for errors.

The HTAnalyzer is still under development. So **DONOT** turn on this config unless you would like to contribute on this feature.

#### computeConstantExpression (_experimental feature_)

Defaults to `false`.

Wether to compute complex constant values expressions like:

```dart
const b = 6
const c = 7
const a = b * c // to compute this value!
```

The Constant Interpreter is still under development. So **DONOT** turn on this config unless you would like to contribute on this feature.

#### removeLineInfo

Defaults to `false`.

Wether dump line info in the code when compile.

If turn on, would shrink the module size. However it will be hard to debug since the line info would be missing in the error messages.

#### removeAssertion

Defaults to `false`.

Wether dump assertion statements when compile.

Since assertions are mainly for check errors during development, and they should be always true in a running code.

If turn on, would shrink the module size.

#### removeDocumentation

Defaults to `false`.

Wether dump documentation comments when compile.

The documentation comments are comments in the form of `///` or `/** */`.

You can access to them by the `help()` method provided by the runtime.

If turn on, would shrink the module size.

#### showDartStackTrace

Defaults to `false`.

Wether show Dart stack trace info on error.

#### showHetuStackTrace

Defaults to `false`.

Wether show hetu stack trace info on error.

#### stackTraceDisplayCountLimit,

Defaults to `5`.

The limit for stack strace informations.

#### processError

Defaults to `true`.

Wether to add runtime information into the errors (e.g. lineinfo).

If set to false, errors would be raised as it is.

#### allowVariableShadowing

Defaults to `true`.

[Referrence](../../grammar/strict_mode/readme.md#variable-shadowing)

#### allowImplicitVariableDeclaration

Defaults to `false`.

[Referrence](../../grammar/strict_mode/readme.md#implicit-variable-declaration)

#### allowImplicitNullToZeroConversion

Defaults to `false`.

[Referrence](../../grammar/strict_mode/readme.md#zero-value)

#### allowImplicitEmptyValueToFalseConversion

Defaults to `false`.

[Referrence](../../grammar/strict_mode/readme.md#truth-value)

#### checkTypeAnnotationAtRuntime

Defaults to `false`.

If this set to `true`, the interpreter will try to resolve the typename within the type annotation.

```dart
// if checkTypeAnnotationAtRuntime == true and ClassA does not exist
// this line will raise an error in the runtime.
var a: ClassA;
```

#### resolveExternalFunctionsDynamically

Defaults to `false`.

If this set to false, after the first run, the external functions will **remember** the dart function that binded with it.

And you cannot change it even if you bind another external dart function with the same id again later.

If this set to true, the hetu external function will ask the runtime for the dart external function everytime it's called.

This will cost more for efficiency's sake.

#### printPerformanceStatistics

Defaults to `false`.

Wether to print performence info into the standard output.

The output is like this:

```
hetu: 36ms	to parse	[$script_e99c23d0: var globalVar = 0;...]
hetu: 2ms	to bundle	[$script_e99c23d0: var globalVar = 0;...]
hetu: 28ms	to compile	[$script_e99c23d0: var globalVar = 0;...]
hetu: 8ms	to load module	$script_e99c23d0: var globalVar = 0;... (compiled at 2023-03-22 06:53:35 UTC with hetu@0.4.3)
```

### sourceContext

If you need to deal with reading source code from your platform. You can create an instance of a HTResourceContext implementation and pass it into the Hetu instance.

For example:

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

If you installed 'hetu_script_dev_tools' or 'hetu_script_flutter', they will handle the source context for you so you won't need to worry about how to fetch the string content of code.

However if you cannot use these packages(for example if your code are running on web browser), you can use methods below on **HTOverlayContext** to manually manage sources for code to import from.

```dart
void addResource(String fullName, HTSource resource)

void removeResource(String fullName)

void updateResource(String fullName, HTSource resource)
```

[Referrence](../../guide/package/readme.md)

### apis on Hetu class

#### init()

A convenient way to load some shared modules all together when Hetu initted.

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

- **useDefaultModuleAndBinding**: if this is true, hetu will add in default bindings for common Dart objects like print(), String, List, Functions, etc. If this is false, you can only use hetu as a basic expression evaluator for things like '5 \* 8 + 2' but cannot use any functions like '(3.14).truncate()'

- **externalFunctions**: Dart functions to be binded with a external function declaration in Hetu. You can also use **bindExternalFunction** methods to load them later.

- **HTExternalFunctionTypedef**: Dart typedefs to be used when a Hetu function want to be converted to a Dart function when evaluated. You can also use **bindExternalFunctionType** methods to load them later.

- **HTExternalClass**: Dart class bindings to be used by Hetu to get class definitions. You can also use **bindExternalClass** methods to load them later.

#### eval(), evalFile()

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

#### compile(), compileFile(), loadBytecode()

These methods is useful if you want a more efficient runtime for the script. You can compile a source into bytecode. And run it at another time so that the interpreter will skip the parsing, analyzing and compiling process.

If you would like to compile and store the result as physical files. You can check [**command line tool**](../../guide/command_line_tool/readme.md#compile) in the hetu_script_dev_tools package.

## Interact with the script, fetch(), assign(), invoke()

The easiest way to change a variable or call a script function is to just use `eval` method on a literal string like:

```dart
hetu.eval('a = 5')
hetu.eval('someScriptFunction()')
```

However this might cause safety issue or namespace corruption if you cannot control the content of the string. For example, if the string content is fetched from other places like from the user side.

So to avoid to run a actual piece of code. You can use several dedicated apis:

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

The **fetch** and **assign** method can be used to get/set variables defined within the script.

The **invoke** can be used to call a specific function defined within the script.

You can also find invoke method on **HTClass** and **HTInstance** object, or use the **call** method on **HTFunction** object. That is to say, if you have those object passed from script into the Dart.
