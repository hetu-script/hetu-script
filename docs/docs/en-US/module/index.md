# Module

Hetu script codes are a batch of [HTSource] files organized in the form of [HTModule] and [HTLibrary]. If a module contains import statement, the parser will try to fetch another module content by the import path through a [HTContext].

## Module

A module is a single string content. It could be a runtime string literal from dart side. Or it could be a plain text file on your physical disk.

### Source type

Hetu script file have two different way to interpret, controlled by a source [type] parameter in the eval method of the Interpreter class.

- [SourceType.module]: the script file contains only import statement and declarations(variable, function and class). Interpreter can invoke a function immediately after evaluation, the name of the invoked function is given by parameter [invokeFunc], which is commonly 'main'. This is like most app structure in C++, Java and Dart.

- [SourceType.script]: the script file contains all kinds of expression and control statement that is allowed in a anonymous function body (including nested function and class declaration). Everything is immediately evaluated. This is like the usage of most script languages like Javascript, Python and Lua.

## Library

## Context
