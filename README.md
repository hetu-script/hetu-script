# Hetu Script

## Table of Content:

- [Introduction](#introduction)
- [Quick start](#quick-start)
- [Binding](#binding)
- [Command line tool](#command-line-tool)
- [Referrences](#referrences)

## Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter app have hotfix and scripting ability.

[中文介绍](https://github.com/hetu-script/hetu-script/blob/master/doc/zh_Hans/README_ZH.md)

We did not choose to use another existing language to achieve the goal. Because we want to keep the language simple, and keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system, and make the debug process pain-free and remain in Dart realms.

It takes very little time to bind almost anything in Dart/Flutter into Hetu and use almost exactly the same grammar to write your app. And to communicate with classes & functions in Dart is very easy.

## Quick start

Hetu's grammar is close to typescript/kotlin/swift and other modern languages, need very little time to get familar with.

- Optional semicolon.
- Function is declared with 'fun, get, set, construct'.
- Optional type annotation. Variable declared with 'let, const' will infer its type from its initializer expression.

[Syntax referrence](https://github.com/hetu-script/hetu-script/blob/master/doc/en_US/syntax.md)

[语法参考](https://github.com/hetu-script/hetu-script/blob/master/doc/zh_Hans/SYNTAX.md)

In your Dart code, you can interpret a script file:

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
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
  fun greeting => print('Hi! I\'m', name)
}

// This is where the script starts executing.
fun main {
  var ht = Person('Hetu')
  ht.greeting()
}
```

## Binding

Hetu script is purely written in Dart, so passing object to and from script is extremely easy.

Check [this page](https://github.com/hetu-script/hetu-script/blob/master/doc/en_US/binding.md) for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': () => {'greeting': 'hello'},
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

## Command line tool

Hetu has a command line REPL tool for testing. You can activate by the following command:

```
dart pub global activate hetu_script
```

Then you can use the following command in any directory on your computer. (If you are facing any problems, please check this official document about [pub global activate](https://dart.dev/tools/pub/cmd/pub-global))

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

## Referrences:

- [Operator precedence](https://github.com/hetu-script/hetu-script/blob/master/doc/en_US/operator_precedence.md)
- [Bytecode specification](https://github.com/hetu-script/hetu-script/blob/master/doc/en_US/bytecode_specification.md)
