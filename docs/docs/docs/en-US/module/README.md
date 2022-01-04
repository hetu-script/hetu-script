---
title: Module import & export
---

# Module

Hetu script codes are a batch of **HTSource** files. If a source contains import statement, the parser will try to fetch another source content by the import path through the **HTResourceContext**. The default **HTResourceContext** provided by the Interpreter is **HTOverlayContext**, it will not handle physical files and you need to manually add String content into the context for modules to import from.

## Import

Use import statement to import from another script file.

- You can specify a list to limit the symbols imported.
- You can set aliases for the imported symbols as well as the namespace as a whole.

```javascript
import 'game.ht'
import { hello as greeting, calculator } from 'hello.ht' as h

fun main {
  h.greeting()
}
```

## Export

Use export in a source to specify the symbols you wish to let other source access when they import from you.

- If there's no path provided, exported the symbols from the source contains this statement.
- You can give a path after the export keyword, to export other source's content.

```javascript
export {
  hello,
  calculator,
}

export 'game.ht'
export { hello } from 'hello.ht'
```

If you have at least one export statement, nomatter it's a export + 'path' form or export { namelist } form, you wont' inexplicitly export any of the members.

Otherwise, every top level symbol will be exported by default.

## Resource type

Hetu script file have 3 way to interpret, controlled by the **ResourceType type** parameter in the eval method of the Interpreter class or the extension of the source file.

- For **ResourceType.hetuScript**, the source file is organized like a Javascript, Python and Lua file. It has its own namespace. It may contain any expression and control statement that is allowed in a function body (including nested function and class declaration). And every expression is immediately evaluated.

- When **ResourceType** is not provided in interpreter's 'eval' method, interpreter will evaluate the string provided as **ResourceType.hetuLiteralCode**. Other than the code has no namespace. It is the same to **ResourceType.hetuScript**.

-For **ResourceType.hetuModule**, the source file is organized like a C++, Java or Dart app. It only contains import statement and declarations(variable, function and class). The top level variables are lazily initialized (initialize when first used).

When using evalFile method on the interpreter, the source type is inferred from the extension of the file name: '\*.hts' is **ResourceType.hetuScript**, and '\*.ht' is **ResourceType.hetuModule**.

## Import a JSON file

It's possible to import a non-hetu source in your code sometimes. For example, if you imported a JSON file, you will get a HTStruct object from it. Because the syntax of a JSON is fully compatible with Hetu's struct object.

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
