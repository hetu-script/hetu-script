# Hetu Script

## Table of Content:

- [Introduction](#introduction)
- [Binding](#binding)
- [Auto-Binding tools](#auto-binding-tools)
- [Command line tool](#command-line-tool)

## Introduction

[中文介绍](README_ZH.md)

Hetu is a lightweight script language written in Dart for embedding in Flutter apps.

Hetu's grammar is close to typescript/kotlin/swift and other modern languages, hence need very little time to get familar with.

It meant to be used as a scripting language like lua, however, it is made to communicate with classes & functions in Dart very easily.

[Syntax referrence](doc/en_US/SYNTAX.md)

[语法参考](doc/zh_Hans/SYNTAX.md)

In your Dart code, you can interpret an script file by this:

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();
  await hetu.init();
  await hetu.import('hello.ht', invokeFunc: 'main');
}
```

While [hello.ht] is the script file written in Hetu, here is an example:

```typescript
// Define a class.
class Person {
  var name: str
  construct (name: str) {
    this.name = name
  }
  fun greeting {
    print('Hi! I\'m', name)
  }
}

// This is where the script starts executing.
fun main {
  var ht = Person('Hetu')
  ht.greeting()
}
```

Hetu's grammar is almost same to typescript, except a few things:

- Function is declared with [fun].
- Variable declared with keyword [let] or [const] and without a type will be given a type if it has an initialization.

## Binding

To call Dart functions in Hetu, just init Hetu with [externalFunctions].

Then define those dart funtion in Hetu with [external] keyword.

Then you can call those functions in Hetu.

You can pass object from Dart to Hetu by the return value of external functions.

You can pass object from Hetu to Dart by the return value of Interpreter's [invoke] function;

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();
  await hetu.init(externalFunctions: {
    'hello': (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => {'greeting': 'hello'},
  });
  await hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print('dart value:', dartValue)
        dartValue['foo'] = 'bar'
        return dartValue
      }''');

  var hetuValue = hetu.invoke('main');

  print('hetu value: $hetuValue');
}
```

And the output should be:

```
dart value: {greeting: hello}
hetu value: {greeting: hello, foo: bar}
```

## External function convention

External functions (for both global and methods) can be binded as the following type:

```dart
await hetu.init(externalFunctions: {
  'hello': (List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}) => {'greeting': 'hello'},
});
```

or directy as a Dart Function:

```dart
await hetu.init(externalFunctions: {
  'hello': () => {'greeting': 'hello'},
});
```

It's easier to write and read in Dart Function form. However, this way the Interpreter will have to use Dart's [Function.apply] feature to call it. This is normally slower and inefficient than direct call.

## Auto-Binding tools

Thanks to [rockingdice](https://github.com/rockingdice) we now have an automated tool for auto-generate both Dart-side and Hetu-side binding declarations for any Dart classes.

Please check out this repository: [hetu-script-autobinding](https://github.com/hetu-script/hetu-script-autobinding)

## Command line tool

On Windows, there is a hetu.exe under [project_directory/bin] to use in Command line.

Usage:

```

hetu [file_name] [invoke_func]

```

If [file_name] is provided, evaluate the file in [function] mode.

If [invoke_func] is provided, evaluate the file in [module] mode and call a certain function with given name.

If no option is provided, enter REPL mode.

In REPL mode, everything you entered will be evaluated and print out immediately.

```typescript
>>>var a = 42
42
```

If you want to write multiple line in REPL mode, use '\\' to end a line.

```typescript
>>>fun hello {\
return 6 * 7} // press enter
function hello(): any // repl will print out the eval result (in this case the type of this function)
>>>hello()
42 // repl print
>>>
```
