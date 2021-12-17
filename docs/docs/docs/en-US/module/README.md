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

Hetu script file have two different way to interpret, controlled by the **isModule** parameter in the eval method of the Interpreter class and the extension of the source file.

- When **isModule** is not provided or set to false, or the file is of extension '\*.hts', interpreter will evaluate the source as **ResourceType.hetuScript**. This kind of source file is organized like a Javascript, Python and Lua file. It may contain any expression and control statement that is allowed in a function body (including nested function and class declaration). And every expression is immediately evaluated.
- When **isModule** is true, or the file is of extension '\*.ht', interpreter will evaluate the source as **ResourceType.hetuModule**. This kind of source file is organized like a C++, Java or Dart app. It only contains import statement and declarations(variable, function and class). The top level variables are lazily initialized (initialize when first used).

## Import a JSON file

It's possible to import a non-hetu source in your code sometimes. For example, if you imported a JSON file, you will get a HTStruct object from it. Because the syntax of a JSON is fully compatible with Hetu's struct object.

To do so, there are some extra work to be done. You have to tell the **HTResourceContext** to includes JSON files in the beginning.

And you have to give the imported JSON a alias name in your namespace.

Example code (dart part):

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  const root = 'example/script';
  const filterConfig = HTFilterConfig(root, extension: [
    HTResource.hetuModule,
    HTResource.hetuScript,
    HTResource.json,
  ]);
  final sourceContext = HTFileSystemSourceContext(
      root: root,
      includedFilter: [filterConfig],
      expressionModuleExtensions: [HTResource.json]);
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.evalFile('json.hts');
}
```

script code:

```javascript
import 'values.json' as json

print(json)
```
