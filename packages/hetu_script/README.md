# Hetu Script

## Warning

**Hetu is early WIP! We are focusing on making Hetu stable and feature complete right now.**

Discussion group:

Discord: [https://discord.gg/Q8JWQYEw](https://discord.gg/aJedwcRPr8)

QQ 群: 812529118

## Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter apps to have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep the language simple, and keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system, and make the debug process pain-free and remain in Dart realms.

It takes very little time to bind almost anything in Dart/Flutter into Hetu, makes communicating with your existing Dart code very easy.

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

Check [this page](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/syntax/index.md) for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.

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

## Referrences:

- [Operator precedence](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/operator_precedence/index.md)
- [Bytecode specification](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/bytecode_specification/index.md)

## Apps that embedded Hetu:

| Name                       | Author                                        | Description                                                       |                     Download                      | Source        |
| :------------------------- | :-------------------------------------------- | :---------------------------------------------------------------- | :-----------------------------------------------: | :------------ |
| Monster Hunter Otomo: Rise | [rockingdice](https://github.com/rockingdice) | A unofficial game companion app for Capcom's Monster Hunter: Rise | [iOS](https://apps.apple.com/cn/app/id1561983275) | Closed Source |
