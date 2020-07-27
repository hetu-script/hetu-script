## 河图脚本语言（Hetu Script）

河图脚本语言是在Bob Nystrom的[“Crafting Interpreters”](http://www.craftinginterpreters.com/)一书所创建的Lox脚本语言基础上，以Dart写成的。

河图将Lox的语法完全改造成和Dart一致的语法，并且增加了更多的语言特性：

1，赋值、函数调用时的类型检查，用void表示无返回值的函数（但和Dart一样，仍可以完全用dynamic类型来操作数据）
2，类的成员变量、静态变量（static）、外部变量、外部函数的定义、类的构造函数、和Dart一样的get和set函数
3，字面量增加null、List和Map类型（容器内部目前没有做类型检查，都视作dynamic成员）
4，增加了import语句，可以导入其他文件模块
5，增加了Dart调用脚本函数，以及脚本内调用Dart函数的双向绑定（external关键字）
6，增加了命令行式函数调用（用空格而不是括号和逗号分开参数）
7，增加了for...in语法，并且循环中支持break和continue语句

## 简单的使用示例


```dart
import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht');
  hetu.evalf('ht\\main.ht', invokeFunc: 'main');
}
```

输出结果为：
```
the machine says:
the meaning of life, universe and everything
is 42
```

脚本文件'main.ht'的内容如下：

```dart
import 'calculator.ht';

// 程序入口
void main() {
  var cal = Calculator(6, 7);
  cal.calculate();
}

```

脚本文件'calculator.ht'的内容如下：
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

void calculate() {
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

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hythl0day/HetuScript/issues
