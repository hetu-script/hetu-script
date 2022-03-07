# 语言实现细节

大部分情况下，你无须具体了解河图的解释器和编译器等工具是如何实现的。但如果你遇到了一些设计实现底层的问题，可以参考这里的一些介绍。

## 字符串插值（格式化）

河图使用和 Javascript 类似的字符串插值语法。但在编译阶段，实际上这些语句将会编译为类似 C# 的 String.format() 或者 python 的 str.format() 那样的格式。也就是说，在编译时，字符串插值将会用 '{0}', '{1}' 来替换掉原本的 '${expression}' 表达式。解释器会在运行时用运算出的实际值进行替换。所以为了避免出现意料之外的格式化结果，请不要在字符串插值中自己手动写 '{0}', '{1}' 等，如果有此种需求，要改用普通字符串。

## 延迟初始化

对于 **ResourceType.hetuModule** 类型的代码文件，顶层变量声明，以及类中的成员变量成名，其初始化值并不会在一开始就运算出来。而是在第一次调用前才会运算。这样是为了解决循环导入的问题。

## 枚举

枚举值在编译时会被编译成普通的 class。因此所有的枚举值本质上都是普通对象。

例如，下面这个枚举声明：

```dart
enum Country {
  kHungary,
  kJapan,
  kIndia,
}
```

会被编译成：

```dart
class Country {
  final _name;
  Country._(name) {
    _name = name;
  }
  fun toString = 'Country.${_name}'
  static final kHungary = ENUM._('kHungary')
  static final kJapan = ENUM._('kJapan')
  static final kIndia = ENUM._('kIndia')
  static final values = [kHungary, kJapan, kIndia]
}
```

但枚举值在声明时也可以加 external 关键字，这表明这是一个 Dart 中的枚举值。

## 自动分号插入

自动分号插入（Automatic semicolon insertion，缩写 ASI）是一个常见的程序语言技术。主要用于那些可以省略分号，同时又允许多行语句的编程语言中。要了解更多，可以参考[这个页面](https://en.wikibooks.org/wiki/JavaScript/Automatic_semicolon_insertion)。

使用自动分号插入技术的目的是为了避免出现多重语义，也就是编译器对语句的理解可能和用户想要达到的效果不同。

例如下面的代码中，javascript 会在 return 关键字后插入分号。

```javascript
function getObject() {
  if (isReady) return; // a semicolon will always be inserted here automatically by Javascript engine
  {
    // fields
  }
  // some codes
}
```

如果这里没有分号，则会有两种不同理解：

1，如果 if 判断为真，函数返回的是一个对象字面量。

2，如果 if 判断为真，函数在这里直接返回空值。否则，继续执行下面的语句。

类似的多重语义还会发生在圆括号开头的段落中。因为有圆括号除了用来作为表达式分组，也有把前面的表达式当做函数直接执行的意思。

在 Javascript 中，只要你进行了换行，多数情况下都会自动插入一个分号。在河图中，规则则略有变化。

我们只会在以下面这些 token 开头的一行的**上一行**末尾加入分号：

'{', '(', '[', '++', '--'

但如果**上一行**是一个**未结束**语句，则不会加入分号。

未结束语句的意思是以下面这些 token 结尾的行：

'!', '\*', '/', '%', '+', '-', '<', '<=', '>', '>=', '=', '!=', '??', '&&', '||', '=', '+=', '-=', '\*=', '/=', '??=', '.', '(', '{', '[', ',', ':', '->', '=>'.

除此之外，对于 return 关键字。如果后面是新的一行，则我们一定会插入一个分号。

因此如果你想要 return 一个对象字面量，需要其左边的花括号写在 return 的同一行。

类似的，需要将函数定义的左边的花括号写在函数名字或者函数参数的同一行。

## 循环导入

循环导入的意思是，对于代码文件 A 和 B，在 A 中包含了 'import B'的声明，同时在 B 中包含了 'import A'的声明。

如果一个代码文件是 **ResourceType.hetuModule** 类型，解释器会自动处理循环引入问题。但如果代码文件的类型是 **ResourceType.hetuScript**，循环引用会造成 stack overflow 错误，因此你需要自行小心处理这个问题。

## 闭包

在河图中，每一个函数在每次执行时都会创建一个新的命名空间。同时这些命名空间可以访问上层命名空间。这样就会让函数闭包可以直接访问和修改外部定义的变量。

这类似于 Javascript，是一种动态化、运行时的实现方式。而区别于 C++/Rust 中的语法意义上的闭包（lexical closure），后者使用 move 以及按值传递参数等功能实现。
