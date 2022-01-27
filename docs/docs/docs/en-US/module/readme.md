# Module

Hetu script codes are a batch of **HTSource** files. If a source contains import statement, the parser will try to fetch another source content by the import path through the **HTResourceContext**. The default **HTResourceContext** provided by the Interpreter is **HTOverlayContext**, it will not handle physical files and you need to manually add String content into the context for modules to import from.

## Resource type

Hetu script file have 3 way to interpret, controlled by the **ResourceType type** parameter in the eval method of the Interpreter class or the extension of the source file.

- For **ResourceType.hetuScript**, the source file is organized like a Javascript, Python and Lua file. It has its own namespace. It may contain any expression and control statement that is allowed in a function body (including nested function and class declaration). And every expression is immediately evaluated.

- When **ResourceType** is not provided in interpreter's 'eval' method, interpreter will evaluate the string provided as **ResourceType.hetuLiteralCode**. Other than the code has no namespace. It is the same to **ResourceType.hetuScript**.

- For **ResourceType.hetuModule**, the source file is organized like a C++, Java or Dart app. It only contains import statement and declarations(variable, function and class). The top level variables are lazily initialized (initialize when first used).

When using evalFile method on the interpreter, the source type is inferred from the extension of the file name: '\*.hts' is **ResourceType.hetuScript**, and '\*.ht' is **ResourceType.hetuModule**.

## Recursive import

For **ResourceType.hetuModule**, recursive import (i.e. A import from B in the meantime, B import from A) is allowed. However, for **ResourceType.hetuScript**, recursive import would cause stack overflow errors. **You have to manually avoid recursive import in '\*.hts' files.**

## Import a pre-compiled binary module

You can pre-compiled a hetu script package into a binary module for better performance. If you have a such module. You can import it by using special prefix in import path:

```dart
import 'modules:calculate';

final result = calculate()
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
  hetu.loadBytecode(bytes: bytes, moduleName: 'calculate');
  hetu.evalFile('import_binary_module.hts');
}
```

## Import a JSON file

Sometimes we need to import a non-hetu source in your code. For example, if you imported a JSON file, you will get a HTStruct object from it. Because the syntax of a JSON is fully compatible with Hetu's struct object.

To do so, there are some extra work to be done. You have to tell the **HTResourceContext** to includes JSON files in the beginning. And you have to give the imported JSON a alias name in your namespace.

Example code (dart part):

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  const root = 'example/script';
  final sourceContext = HTFileSystemResourceContext(
      root: root,
      expressionModuleExtensions: [HTResource.json, HTResource.jsonWithComments]);
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.eval('''
    import 'values.json' as json
    print(json)
  ''');
}
```
