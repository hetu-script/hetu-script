<p align="center">
  <a href="https://hetu.dev">
    <img alt="hetu script" width="200px" src="https://hetu.dev/image/hetu-logo-large.png">
  </a>
  <h1 align="center">Hetu Script</h1>
</p>

<p align="center">
A lightweight script language written in Dart for embedding in Flutter apps.
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/hetu_script" ><img src="https://img.shields.io/pub/v/hetu_script" /></a>
  <a title="Discord" href="https://discord.gg/sTF73qcS" ><img src="https://img.shields.io/discord/829269197727989760" /></a>
</p>

## Warning

**Hetu is early WIP! We are focusing on making Hetu stable and feature complete right now.**

## Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter apps to have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep the language simple, and keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system, and make the debug process pain-free and remain in Dart realms.

It takes very little time to bind almost anything in Dart/Flutter into Hetu, makes communicating with your existing Dart code very easy.

## Documentation

### [English](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/index.md)

## Quick start

Below is an example to eval a string literal of Hetu code in Dart.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    fun main {
      var ht = {
        name: 'Hetu',
        greeting: () {
          print('Hi! I\'m', this.name)
        }
      }
      ht.greeting()
    }
  ''', invokeFunc: 'main');
}
```

Hetu's grammar is close to typescript/kotlin/swift and other modern languages, need very little time to get familar with.

- Optional semicolon.
- Function is declared with 'fun, get, set, construct'.
- Optional type annotation. Variable declared will infer its type from its initializer expression.
- Support for traditional class style OOP and javascript-like prototyped based OOP, and also functional programming as function is a first class value. You can choose whatever style you want.

[Syntax referrence](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/syntax/index.md)

## Binding

Hetu script is purely written in Dart, so passing object to and from script is extremely easy.

Check [this page](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/binding/index.md) for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.

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

## Discussion group

Discord: https://discord.gg/sTF73qcS
中文交流请加 QQ 群：812529118

## Support

You can support my project by simply giving it a star on GitHub.

Or you can buy me a coffee:

[![Buy me a coffee](https://hetu.dev/image/buy_me_a_coffee_small.png)](https://www.buymeacoffee.com/chengfubeiming)
