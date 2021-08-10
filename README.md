# Hetu Script

## Warning

**Hetu is early WIP! We are focusing on making Hetu stable and feature complete right now.**

Discussion group:

Discord: [https://discord.gg/Q8JWQYEw](https://discord.gg/aJedwcRPr8)

QQ 群: 812529118

## Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter app have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep the language simple, and keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system, and make the debug process pain-free and remain in Dart realms.

It takes very little time to bind almost anything in Dart/Flutter into Hetu and use similar grammar to write your app. And to communicate with classes & functions in Dart is very easy.

## Quick start

Hetu's grammar is close to typescript/kotlin/swift and other modern languages, need very little time to get familar with.

- Optional semicolon.
- Function is declared with 'fun, get, set, construct'.
- Optional type annotation. Variable declared will infer its type from its initializer expression.

[Syntax referrence](https://github.com/hetu-script/docs/blob/main/docs/en-US/syntax/index.md)

In your Dart code, you can interpret a script file:

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.evalFile('hello.ht', invokeFunc: 'main');
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

## Binding

Hetu script is purely written in Dart, so passing object to and from script is extremely easy.

Check [this page](https://github.com/hetu-script/docs/blob/main/docs/en-US/binding/index.md) for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init(externalFunctions: {
    'hello': () => {'greeting': 'hello'},
  });
  hetu.eval(r'''
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

Then you can use command line tool 'hetu' in any directory on your computer. (If you are facing any problems, please check this official document about [pub global activate](https://dart.dev/tools/pub/cmd/pub-global))

More information can be found by enter [hetu -h].

If no command and option is provided, enter REPL mode.

In REPL mode, every exrepssion you entered will be evaluated and print out immediately.

If you want to write multiple line in REPL mode, use '\\' to end a line.

```typescript
>>>var a = 42
>>>a
42
>>>fun hello {\
return a }
>>>hello
function hello() -> any // repl print
>>>hello()
42 // repl print
>>>
```

## Referrences:

- [Operator precedence](https://github.com/hetu-script/docs/blob/main/docs/en-US/operator_precedence/index.md)
- [Bytecode specification](https://github.com/hetu-script/docs/blob/main/docs/en-US/bytecode_specification/index.md)

## Apps that embedded Hetu:

| Name                       | Author                                        | Description                                                       |                     Download                      | Source        |
| :------------------------- | :-------------------------------------------- | :---------------------------------------------------------------- | :-----------------------------------------------: | :------------ |
| Monster Hunter Otomo: Rise | [rockingdice](https://github.com/rockingdice) | A unofficial game companion app for Capcom's Monster Hunter: Rise | [iOS](https://apps.apple.com/cn/app/id1561983275) | Closed Source |
