<p align="center">
  <a href="https://hetu.dev">
    <img alt="hetu script" width="200px" src="https://hetu.dev/image/hetu-logo-large.png">
  </a>
  <h1 align="center">Hetu Script</h1>
</p>

<p align="center">
A lightweight scripting language written in Dart for embedding in Flutter apps.
</p>

<p align="center">
  <a href="https://github.com/hetu-script/hetu-script/blob/main/packages/hetu_script/README_ZH.md">简体中文页面</a>
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/hetu_script" >
    <img src="https://img.shields.io/pub/v/hetu_script" />
  </a>
  <a title="VSCode Extension" href="https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript" >
    <img src="https://img.shields.io/badge/vscode--market-version.0.0.14-blue" />
  </a>
  <a title="Discord" href="https://discord.gg/aJedwcRPr8" >
    <img src="https://img.shields.io/discord/829269197727989760" />
  </a>
</p>

## Introduction

Hetu is a lightweight scripting language purely written in Dart for embedding in Flutter apps. Our goal is to enable Flutter app & game to have hotfix and scripting ability.

**[Documentation](https://hetu.dev/docs/en-US/) [中文文档](https://hetu.dev/docs/zh-Hans/)**

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
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
```

You can check the [documentation](https://hetu.dev/docs/en-US/) for more information on the [grammar](https://hetu.dev/docs/en-US/grammar/) and [binding](https://hetu.dev/docs/en-US/guide/binding/).

## IDE extension

If you are using VS Code, you can download [this extension](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript) to get basic highlight and dart snippets on bindings.

## Command line tool

We have a command line REPL tool for quick testing. You can activate by the following command:

```
dart pub global activate hetu_script_dev_tools
```

Then you can use command line tool 'hetu' in any directory on your computer.

More information about the command line tool can be found by enter 'hetu -h'.

If no arguments is provided, enter REPL mode.

In REPL mode, every exrepssion you entered will be evaluated and print out immediately.

If you want to write multiple line in REPL mode, use '\\' to end a line.

```typescript
>>>var a = 42
null // repl print
>>>a
42 // repl print
>>>function meaning {\
return a }
null // repl print
>>>meaning
meaning() -> any // repl print
>>>hello()
42 // repl print
```

You can check this [official document](https://dart.dev/tools/pub/cmd/pub-global) for more information on 'pub global activate'.

## Discussion group

Discord: [https://discord.gg/aJedwcRPr8](https://discord.gg/aJedwcRPr8)

中文交流可以加 QQ 群：812529118

## Support

You can support my project by simply giving it a star on GitHub.

Or you can buy me a coffee:

[![Buy me a coffee](https://hetu.dev/image/buy_me_a_coffee_small.png)](https://www.buymeacoffee.com/chengfubeiming)
