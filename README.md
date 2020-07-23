## Usage

简单的使用示例：

```dart
import 'package:hetu_script/hetu.dart';

void main() {
  var hetu = Hetu();
  // 执行脚本文件，以'main'作为入口函数
  hetu.evalf('test\\calculator.hs', invokeFunc: 'main');

  // 以命令行模式解析
  hetu.evalc('System.print hello world 42!');
}
```

输出结果为：
the meaning of life, universe and everything is 42
hello
world
42!

Content of 'test.hs':

```dart

// 类的定义
class calculator {
  // 成员变量
  num x;
  num y;

  // 带有参数的构造函数
  calculator(num x, num y) {
    // this关键字、get取值和赋值、语句块中同名变量的覆盖
    this.x = x;
    this.y = y;
  }

  // 带有返回类型的成员函数
  num meaning() {
    // 不通过this直接使用成员变量
    return x * y;
  }
}

// 程序入口 
void main(){
  // 带有初始化语句的变量定义
  // 从类的构造函数获得对象的实例
  var cal = calculator(6, 7);
  
  // 调用外部静态成员函数，字符串类型转换、运算和检查
  System.print('the meaning of life, universe and everything is ' + cal.meaning().toString());
}

```


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hythl0day/HetuScript/issues
