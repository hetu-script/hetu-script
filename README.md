## 河图脚本语言（Hetu Script）

河图是一个以 Dart 写成的脚本语言解释器，同时也是一个脚本语言。主要使用场景是嵌入一个 Dart 宿主程序中，然后宿主程序通过创造一个脚本解释器对象，动态的加载脚本文件（以 .ht 作为后缀名），达到脚本化的目的。从而可以在不重新发布 Dart 程序的情况下，改变用户端的逻辑和体验，实现热更新。

河图脚本语言是在 Bob Nystrom 的[“Crafting Interpreters”](http://www.craftinginterpreters.com/)一书所创建的 Lox 脚本语言基础上修改而成的，原书所使用的语言是 Java 和 C，这里也改成了用 Dart 实现，这样更方便以 Dart 作为宿主程序，直接调用 Dart 的库等。

在 Lox 基础上增加的类 Dart 语法：

- 声明变量、函数时可以指定类型，使得赋值、函数调用、函数返回时可以检查类型（但仍可以用 dynamic 类型略去检查），void 表示无返回值的函数。
- 函数可以有可选参数列表（放在方括号“[]”里面），可选参数可以有默认初始化值。
- 类的成员变量、类成员的私有声明、类的静态变量（static）、类成员绑定外部变量和函数（external）、类的构造函数、和 Dart 一样的 get 和 set 函数。
- null 字面量，is 类型判断，List 和 Map 两种容器类型（容器内部目前没有做类型检查，都视作 dynamic 成员）。
- import 语句，可以导入其他河图脚本模块。
- 支持 Dart 调用脚本的函数，以及脚本调用 Dart 的函数的双向绑定（external 关键字）。
- for...in 语法，并且循环中支持 break 和 continue 语句。
- 可以以命令行式的语法进行函数调用（用空格分开参数，而不用括号和逗号）。

一些不同于 Dart 的语法：

- 变量一定以var声明，变量类型以冒号形式跟在变量名字后面，如果声明时省略类型，则会从初始化语句推导。如果既没有类型也没有初始化语句，则等同于dynamic。例子：

```dart
var hello: String = 'hello'
var truth = 42
var file: dynamic;
```

- 函数声明时，可以使用“(?)”形式的参数列表声明，这样表示可以接受任意数量和任意类型的传入参数。在实际调用时，可以使用 arguments（List 类型）来访问参数。
- 可以像 JavaScript 那样，直接将一个 Map 赋值给一个 Object。例子：

```dart
class HelloWord {
  var hello: num;
  var world: bool;
}
HelloWord m = {"hello": 42, "world": true};
```

不过和 JavaScript 不同的地方在于，河图不支持匿名类，因此必须事先声明类，然后才能赋值。赋值时，类中有和 Map 的 key 同名的成员变量，并且类型也符合，才能赋值成功。

- 函数必须以关键字声明，关键字包括：init（类的构造函数），get/set（类成员变量的赋值和取值），func（自由函数），函数的返回值以冒号形式跟在参数列表后面。参数列表本身如果是空，也可以连括号也省略不写。例子：

```dart
func main {}
func main(): void {}
func greeting(val: num): num {}
```


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

func main {
  hetu.init(workingDir: 'ht_excample');
  hetu.evalf('ht_excample\\members.ht', invokeFunc: 'main');
}
```

输出结果为：

```
hello! I'm the calculator
42
hello! I'm the machine
```

脚本文件'members.ht'内容如下：

```dart
class Wrapper {
  var cal: Calculator;
}

// 类的定义
class Calculator {
  // 成员变量
  var x: num;
  var y: num;

  // 静态私有成员
  static var _name = 'the calculator';

  static get name: String {
    // 类中的静态函数只能访问类中的静态对象
    return _name;
  }

  static set name(new_name: String) {
    _name = new_name;
    greeting();
  }

  static func greeting {
    Console.print('hello! I\'m ' + _name);
  }

  // 带有参数的构造函数
  init (x: num, y: num) {
    // 语句块中会覆盖上一级的同名变量，所以这里使用this关键字指定
    this.x = x;
    this.y = y;
    greeting();
    Console.print(meaning().toString());
  }

  // 带有返回类型的成员函数
  func meaning: num {
    // 可以不通过this直接使用成员变量
    return x * y;
  }
}

// 程序入口
func main {
  // 带有初始化语句的变量定义
  // 从类的构造函数获得对象的实例

  var w = Wrapper();
  w.cal = Calculator(6, 7);
  // Calculator._name = 'the machine'; // 错误：不能在类代码之外访问私有变量
  // setter函数
  Calculator.name = 'the machine';
  // Console.writeln(cal.meaning()); // 错误：参数类型不匹配
  // 调用外部函数，访问类静态变量，getter函数，调用外部成员函数，字符串类型检查

  // 列表的创建和添加元素
  // var list = [Calculator.name + ' says:'];
  // list.add('the meaning of life, universe and everything');
  // list.add('is ' + w.cal.meaning().toString());

  // for (var i in list) {
  //   Console.print(i);
  // }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/hythl0day/HetuScript/issues).
