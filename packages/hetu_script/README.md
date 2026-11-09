<p align="center">
  <a href="https://hetu-script.github.io/">
    <img alt="hetu script" width="200px" src="https://hetu-script.github.io/image/hetu-logo-large.png">
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

**[Documentation](https://hetu-script.github.io/docs/en-US/) [中文文档](https://hetu-script.github.io/docs/zh-Hans/)**

## Features

- Modern programming language syntax likes typescript/kotlin/swift, need very little time to get familiar with.
- Full scripting language abilities: class OOP, prototype OOP, FP, module, errors, etc.
- JavaScript-friendly APIs: use familiar names like `push`, `filter`, `padStart`, `Math.PI`, `Promise.resolve` and `console.warn`, as aliases of the Dart-backed implementations.
- Runs on all platforms that flutter supports, including web browsers and desktop.
- Extremely easy on binding, call Dart functions in script or call script functions in Dart with just one line.

Test Hetu script in the online **[playground](https://hetu-script.github.io/codepad/)**.

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

You can check the [documentation](https://hetu-script.github.io/docs/en-US/) for more information on the [grammar](https://hetu-script.github.io/docs/en-US/grammar/) and [binding](https://hetu-script.github.io/docs/en-US/guide/binding/).

## JavaScript-friendly standard library

If you come from JavaScript or TypeScript, many standard library APIs can be used with the names you already know. These are aliases of the Dart-backed implementations, so script values stay fully interoperable with the Dart host:

```typescript
var list = [1, 2, 3]
list.push(4)
var evens = list.filter((n) => n % 2 == 0).toList()

var text = '7'.padStart(3, '0') // '007'
var max = Math.max(3, 1, 4, 1, 5) // 5

Promise.resolve(42).then((value) => print(value))
console.warn('done')
```

Note that the behavior always follows the Dart SDK (for example, `filter` returns a lazy `Iterable`). Check the [JavaScript developers guide](https://hetu-script.github.io/docs/en-US/guide/javascript/) for the full alias table and the differences to watch out for.

## Auto-binding generator

The `hetu_script_dev_tools` package includes an automatic binding generator for Dart classes, enums, and function typedefs marked with `@HTBinding()`. It generates both Dart-side `HTExternalClass` bindings and Hetu-side `external class` declarations.

You can use it with build_runner:

```bash
dart pub add --dev hetu_script_dev_tools build_runner
dart run build_runner build
```

Or generate bindings directly with the CLI:

```bash
hetu bind -u lib/src -o gen/dart -s gen/ht
```

See the [binding guide](https://hetu-script.github.io/docs/en-US/guide/binding/#auto-binding-tools) for details.

## IDE extension

If you are using VS Code, you can download [this extension](https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript) to get basic highlight and dart snippets on bindings.

## Command line tool

We have a command line REPL tool for quick testing. You can install it globally with `dart install`:

```
dart install https://github.com/hetu-script/hetu-script.git --git-path packages/hetu_script_dev_tools
```

Or install from a local path:

```
dart install --source path /path/to/hetu-script/packages/hetu_script_dev_tools
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

You can check this [official document](https://dart.dev/tools/dart-install) for more information on 'dart install'.

## Support

You can support my project by simply giving it a star on GitHub.

Or you can buy me a coffee:

[![Buy me a coffee](https://hetu-script.github.io/image/buy_me_a_coffee_small.png)](https://www.buymeacoffee.com/chengfubeiming)
