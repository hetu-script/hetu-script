# Package & Module

## Source code module

You can use **import** declaration within your code to include other source. The interpreter will interpret those imported sources first.

## Bytecode module

You can use **compile()** to make a single file bytecode module. The compiler with automatically compile every other source that the code imported.

## Resource context

If a source contains import statement, the parser will try to fetch another source content by the import path through a helper class **HTResourceContext**. The default **HTResourceContext** provided by the Interpreter is **HTOverlayContext**, it will not handle physical files and you need to manually add String content into the context before you run the script for it to import from.

## Resource type

Hetu script file have 3 way to interpret, controlled by the **ResourceType type** parameter in the eval method of the Interpreter class or the extension of the source file.

- When **ResourceType** is not provided in interpreter's 'eval' method, interpreter will evaluate the string provided as **ResourceType.hetuLiteralCode**. Other than the code use **global** as its namespace. It is the same to **ResourceType.hetuScript**.

- For **ResourceType.hetuScript**, the source file is organized like a Javascript, Python and Lua file. It has its own namespace. It may contain any expression and control statement that is allowed in a function body (including nested function and class declaration). And every expression is immediately evaluated.

- For **ResourceType.hetuModule**, the source file is organized like a C++, Java or Dart app. It only contains import statement and declarations(variable, function and class). The top level variables are lazily initialized (initialize when first used).

When using **evalFile** method on the interpreter, the source type is inferred from the extension of the file name: '\*.hts' is **ResourceType.hetuScript**, and '\*.ht' is **ResourceType.hetuModule**.

## Import a pre-compiled binary module

You can [pre-compiled a hetu script package](../command_line_tool/readme.md#compile) into a binary module for better performance. If you have a such module. You can import it by using special prefix in import path. Note that for anlysis purpose, you **have to** provide a alias name for this imported module.

```dart
import 'module:calculate' as calculate;

final result = calculate.calculate()
```

However, to do so, you have to load the bytecode before you can import it in your script. This is a example to pre-load a pre-compiled binary file:

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

## Import a JSON file

Sometimes we need to import a non-hetu source in your code. For example, if you imported a JSON file, you will get a HTStruct object from it. Because the syntax of a JSON is fully compatible with Hetu's struct object.

The two implementation of HTResourceContext (HTFileSystemResourceContext & HTAssetResourceContext) will automatically include json and json5 file extensions, and you can import them as normal source files.

Example code (dart part):

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

Note that you **have to** provide a alias name for this imported json file.
