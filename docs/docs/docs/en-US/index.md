---
title: Introduction - Hetu Script Language
---

# Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter apps to have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system. This will keep this language simple and focus on what we actually need.

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

Hetu's [grammar](syntax/index.md) is close to typescript/kotlin/swift and other modern languages.

- Semicolon is optional.
- Function starts with a keyword like 'fun, get, set, construct'.
- Support both class based OOP and prototype based OOP, and also functional programming. You can choose whatever style you want.
- Type annotation is optional. Variable declared will infer its type from its initializer expression. (The static analysis is still WIP.)

## Binding

[Communicating with Dart](binding/index.md) is very easy. You can directly pass common value types from and to script.

Below is an example to pass a Map to script, modify it in script and get it back:

```dart
import 'package:hetu_script/hetu_script.dart'

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

## VScode extension

If you are using VSCode as your editor, you can download [this extension](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript) to get basic highlight and snippets features.
