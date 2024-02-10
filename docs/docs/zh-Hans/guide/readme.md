# 简介

河图是一个专为 Flutter 打造的轻量型嵌入式脚本语言。它用纯 Dart 写成，因此可以非常轻易的嵌入 Flutter APP，和你的现有代码交互。开发这个语言的主要目的是为了实现 APP 动态布局、对已经发布的程序进行轻量级热更新、以及游戏程序的脚本框架等等在 Flutter 中受限制的语言能力。

目前已经有一些框架为了相似的目的而存在，例如可以动态调用 Lua 语言的[Lua Dardo](https://pub.dev/packages/lua_dardo)，可以根据 Json 生成界面的[Flutter Fair](https://fair.58.com/zh/)，等等。还有一些如 [Kraken](https://openkraken.com/) 和 [MXFlutter](https://github.com/tencent/mxflutter) 等方案试图完全将 Flutter APP 前端化。这些方案大多都极为笨重（依托于 V8 等 Javascript 引擎）。并且需要开发者维护一整套胶水方案来达到目的。

而河图脚本语言的目的则是为了以最小代价实现类似的目的：只需要导入一个库 + 一行代码即可动态化。

## 快速上手

下面是一个在 Dart 程序中解析一段脚本语言的例子：

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
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

可以看到，河图尽管是一个新语言，但它的[语法](syntax/readme.md)类似 typescript/kotlin/swift 等现代语言，一目了然，只需要几分钟了解下一些关键区别就可以开始写代码了：

- 语句末尾的分号可写可不写。

- 函数声明类似 Kotlin，需要以关键字开头，函数关键字根据功能不同，包括：**function, get, set, constructor** 等等。

- 语法既支持传统 C++/Java 的以 class 为基础的面向对象，也支持 Javascript 的以原型链为基础的面向对象，也支持各种函数式写法，用户可以根据需求任选风格。

- 支持在关键字声明后加上类型注解（静态类型分析还在开发中，目前尚未实现）。

## 绑定

[河图和 Dart 的交互](binding/readme.md)简单到令人发指。大多数时候你都可以直接向脚本中传递 Dart 的数值，也可以直接使用脚本传回的对象。

下面的代码展示了一个在 Dart 中定义一个函数，然后在脚本中调用，然后再在 Dart 中读取返回值的例子：

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
