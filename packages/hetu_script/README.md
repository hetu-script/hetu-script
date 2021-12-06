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
  <a title="VSCode Extension" href="https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript" ><img src="https://vsmarketplacebadge.apphb.com/version/hetu-script.hetuscript.svg" /></a>
  <a title="Discord" href="https://discord.gg/sTF73qcS" ><img src="https://img.shields.io/discord/829269197727989760" /></a>
</p>

## Warning

**Hetu is early WIP! We are focusing on making Hetu stable and feature complete right now.**

## Introduction

Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter apps to have hotfix and scripting ability.

We did not choose to use another existing language to achieve the goal. Because we want to keep it away from interference of other language's complex implementation and their irrelative-to-Flutter eco-system. This will keep this language simple and focus on what we actually need.

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

Hetu's [grammar](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/syntax/index.md) is close to typescript/kotlin/swift and other modern languages.

- Semicolon is optional.
- Function starts with a keyword like 'fun, get, set, construct'.
- Support both class based OOP and prototype based OOP, and also functional programming. You can choose whatever style you want.
- Type annotation is optional. Variable declared will infer its type from its initializer expression. (The static analysis is still WIP.)

## Binding

Becuase it is written in pure Dart, [communicating with it](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/binding/index.md) is very easy.

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

Check [this page](https://github.com/hetu-script/hetu-script/blob/master/docs/docs/en-US/binding/index.md) for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.

## VScode extension

If you are using VSCode as your editor, you can download [this extension](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript) to get basic highlight and snippets features.

## Command line tool

We have a command line REPL tool for quick testing. You can activate by the following command:

```
dart pub global activate hetu_script_dev_tools
// or you can use a git url or local path:
// dart pub global activate --source path G:\_dev\hetu-script\packages\hetu_script_dev-tools
```

Then you can use command line tool 'hetu' in any directory on your computer.

More information about the command line tool can be found by enter [hetu -h].

If no arguments is provided, enter REPL mode.

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

If there's any problems, you can check this official document about [pub global activate](https://dart.dev/tools/pub/cmd/pub-global).

## Discussion group

- Discord: https://discord.gg/sTF73qcS
- 中文交流请加 QQ 群：812529118

## Support

You can support my project by simply giving it a star on GitHub.

Or you can buy me a coffee:

[![Buy me a coffee](https://hetu.dev/image/buy_me_a_coffee_small.png)](https://www.buymeacoffee.com/chengfubeiming)
