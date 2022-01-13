# Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter apps to have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system. This will keep this language simple and focus on what we actually need.

## Quick start

Below is an example to evaluate a piece of Hetu code in string literal form in Dart.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var ht = {
      name: 'Hetu',
      greeting: () {
        print('Hi! I\'m', this.name)
      }
    }
    ht.greeting()
  ''', isModule: true);
}
```

Hetu's [grammar](syntax/readme.md) is close to typescript/kotlin/swift and other modern languages.

- Semicolon is optional.
- Function starts with a keyword like 'fun, get, set, construct'.
- Support both class based OOP and prototype based OOP, and also functional programming. You can choose whatever style you want.
- Type annotation is optional. Variable declared will infer its type from its initializer expression. (The static analysis is still WIP.)

## Binding

[Communicating with Dart](binding/readme.md) is very easy. You can directly pass common value types from and to script.

This example shows an basic usage of binding:

1, define a dart function.

2, use it to pass a Map to script.

3, directly modify it in script and get it back.

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init(externalFunctions: {
    'hello': () => {'greetings': 'greetings from Dart!'},
  });
  var hetuValue = hetu.eval(r'''
      external fun hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
```

## VScode extension

If you are using VSCode as your editor, you can download [this extension](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript) to get highlight for hetu code and some useful snippets for Dart code.
