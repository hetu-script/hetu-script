---
title: Module import & export - Hetu Script Language
---

# Module

Hetu script codes are a batch of **HTSource** files organized in the form of **HTModule**. If a module contains import statement, the parser will try to fetch another module content by the import path through the **HTResourceContext**. The default **HTResourceContext** provided by the Interpreter is **HTOverlayContext**, it will not handle physical files and you need to manually add String content into the context for modules to import from.

## Source type

Hetu script file have two different way to interpret, controlled by the **isScript** parameter in the eval method of the Interpreter class.

- When **isScript** is not provided or set to false, interpreter will evaluate the source as **SourceType.module**. This kind of source file is organized like a C++, Java or Dart app. It only contains import statement and declarations(variable, function and class). The top level variables are lazily initialized (initialize when first used).
- When **isScript** is true, interpreter will evaluate the source as **SourceType.script**. This kind of source file is organized like a Javascript, Python and Lua file. It may contain any expression and control statement that is allowed in a function body (including nested function and class declaration). And every expression is immediately evaluated.

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

Use export in a module to specify the symbols you wish to let other module access when they import from you.

- If there's no path provided, exported the symbols from the source contains this statement.
- You can give a path after the export keyword, to export other module's content.

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
