## 河图脚本语言（Hetu Script）

河图是一个以 Dart 写成的脚本语言解释器，同时也是一个脚本语言。主要使用场景是嵌入一个 Dart 宿主程序中，然后宿主程序通过创造一个脚本解释器对象，动态的加载脚本文件（以 .ht 作为后缀名），达到脚本化的目的。从而可以在不重新发布 Dart 程序的情况下，改变用户端的逻辑和体验，实现热更新。

河图脚本语言是在 Bob Nystrom 的[“Crafting Interpreters”](http://www.craftinginterpreters.com/)一书所创建的 Lox 脚本语言基础上修改而成的，原书所使用的语言是 Java 和 C，这里也改成了用 Dart 实现，这样更方便以 Dart 作为宿主程序，直接调用 Dart 的库等。

因为使用目的主要是嵌入现有的 Dart 语言使用，因此河图特意将 Lox 的语法改造成和 Dart 的语法规则和写作风格基本一致，并且在 Lox 的基础上增加了一些实用的语言特性：

在 Lox 基础上增加的类 Dart 语法：

- 声明变量、函数时可以指定类型，使得赋值、函数调用、函数返回时可以检查类型（但仍可以用 dynamic 类型略去检查），void 表示无返回值的函数。
- 函数可以有可选参数列表（放在方括号“[]”里面），可选参数可以有默认初始化值。
- 类的成员变量、类成员的私有声明、类的静态变量（static）、类成员绑定外部变量和函数（external）、类的构造函数、和 Dart 一样的 get 和 set 函数。
- null 字面量，is 类型判断，List 和 Map 两种容器类型（容器内部目前没有做类型检查，都视作 dynamic 成员）。
- import 语句，可以导入其他河图脚本模块。
- 支持 Dart 调用脚本的函数，以及脚本调用 Dart 的函数的双向绑定（external 关键字）。
- for...in 语法，并且循环中支持 break 和 continue 语句。

一些不同于 Dart 的语法：

- 可以以命令行式的语法进行函数调用（用空格分开参数，而不用括号和逗号）。
- 函数声明时，可以使用“(? args)”形式的参数列表声明，这样表示可以接受任意数量和任意类型的传入参数。在实际调用时，可以使用 args（List 类型）来访问参数。这里 args 也可以改成别的名字。
- 可以像 JavaScript 那样，直接将一个 Map 赋值给一个 Object。例子：

```dart
class HelloWord {
  num hello;
  bool world;
}
HelloWord m = {"hello": 42, "world": true};
```

不过和 JavaScript 不同的地方在于，河图不支持匿名类，因此必须事先声明类，然后才能赋值。赋值时，类中有和 Map 的 key 同名的成员变量，并且类型也符合，才能赋值成功。

## 简单的使用示例

在 Dart 工程中的 pubspec.yamal 中引入河图库（以路径形式引入）：

```yaml
dependencies:
  hetu_script:
    path: ../../HetuScript/
```

使用公共对象“hetu”初始化工作目录，然后读取脚本文件：

```dart
import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_excample');
  hetu.evalf('ht_excample\\members.ht', invokeFunc: 'main');
}
```

输出结果为：

```
the machine says:
the meaning of life, universe and everything
is 42
```

脚本文件'members.ht'内容如下：

```dart
import 'hetu:core';

// 类的定义
class Calculator {
  // 成员变量
  num x;
  num y;

  // 静态私有成员
  static String _name = 'the calculator';

  static String get name {
    // 类中的静态函数只能访问类中的静态对象
    return _name;
  }

  static set name(String new_name) {
    _name = new_name;
  }

  // 带有参数的构造函数
  Calculator(num x, num y) {
    // 语句块中会覆盖上一级的同名变量，所以这里使用this关键字指定
    this.x = x;
    this.y = y;
  }

  // 带有返回类型的成员函数
  num meaning() {
    // 可以不通过this直接使用成员变量
    return x * y;
  }
}

// 程序入口
void main() {
  // 带有初始化语句的变量定义
  // 从类的构造函数获得对象的实例
  Calculator cal = Calculator(6, 7);
  // Calculator._name = 'the machine'; // 错误：不能在类代码之外访问私有变量
  // setter函数
  Calculator.name = 'the machine';
  // Console.writeln(cal.meaning()); // 错误：参数类型不匹配
  // 调用外部函数，访问类静态变量，getter函数，调用外部成员函数，字符串类型检查

  // 列表的创建和添加元素
  var list = [Calculator.name + ' says:'];
  list.add('the meaning of life, universe and everything');
  list.add('is ' + cal.meaning().toString());

  for (var i in list) {
    Console.print(i);
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/hythl0day/HetuScript/issues).
