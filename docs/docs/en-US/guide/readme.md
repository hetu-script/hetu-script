## Introduction

Hetu is a lightweight scripting language purely written in Dart for embedding in Flutter apps. Our goal is to enable Flutter app & game to have hotfix and scripting ability.

**[Documentation(English)](https://hetu.dev/docs/en-US/)**

## Features

- Modern programming language syntax likes typescript/kotlin/swift, need very little time to get familiar with.
- Full scripting language abilities: class OOP, prototype OOP, FP, module, errors, etc.
- Runs on all platforms that flutter supports, including web browsers and desktop.
- Extremely easy on binding, call Dart functions in script or call script functions in Dart with just one line.

Test Hetu script in the online **[playground](https://hetu.dev/codepad/)**.

## Quick start

To eval a string literal of Hetu code in Dart.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var ht = {
      name: 'Hetu',
      greeting: () {
        print('Greetings from ${this.name}!')
      }
    }
    ht.greeting()
  ''');
}
```

To pass a Map to script, modify it in script and get it back:

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init(externalFunctions: {
    'hello': () => {'greetings': 'greetings from Dart!'},
  });
  var hetuValue = hetu.eval(r'''
      external function hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of last expression
      ''');

  print('hetu value: $hetuValue');
}
```
