# 河图脚本语言

A lightweight script language & its interpreter written purely in Dart, intended to be embedded in Flutter & Dart programs for purposes like hotfixes and game scripting.

河图的语言大体上和 typescript 比较接近，类型用冒号声明，语句结尾可以省略分号。河图的变量会从声明推断其类型，并且不会做自动转换。另外函数声明使用 fun 关键字。

## Hello world

在 Dart 程序中引入河图的库，然后初始化河图环境，读取并解释一个外部脚本文件：

```typescript
import 'package:hetu_script/hetu.dart';

void main() async {
  var hetu = await HetuEnv.init();
  await hetu.evalf('hello.ht', invokeFunc: 'main');
}
```

脚本文件内容：

```typescript
// Define a class.
class Person {
    // Define a member function.
    fun greeting(name: String) {
      // Print to console.
      print('hello ', name)
    }
}

// This is where the script starts executing.
fun main {
  // Declare and initialize variables.
  var number = (6 * 7).toString()
  var jimmy = Person()
  jimmy.greeting(number);
}
```

除了函数声明使用 fun 关键字，变量声明会自动推断其类型，并且解释表达式时不会做类型自动转换之外，河图的语言的语法大体上和 typescript 相同。

## 保留字

null, static, var, let, any, namespace, as, abstract, class, fun, init, get, set, this, super, extends, implements, mixin, external, library, import, break, continue, for, in, if, else, return, while, when, is

## 变量

河图中的变量声明一概以 var 开头，类型声明是可选项，如果有初始化，则会从初始化值的类型推断变量类型。否则会声明为 any 类型。

```typescript
var name = 'naruto'
var year = 2020
var fineStructureConstant: num  = 1 / 137
var isTimeTravelSuccessful: bool = true
var gasGiants = ['Jupiter', 'Saturn', ]
var skill<String> = {
  'tags': ['attack'],
  'script': '//path/to/skill_script.ht',
}
```

## 控制语句

```typescript
if (year >= 2001) {
  print('21st century');
} else if (year >= 1901) {
  print('20th century');
}

for (var planet in gasGiants) {
  print(planet);
}

while (year < 2040) {
  year = year + 1;
}
```

## 函数

```typescript
int fib(int n) {
  if (n == 0 || n == 1) return n;
  return fib(n - 1) + fib(n - 2);
}

var result = fib(10);
```

## 类

```typescript

```

## 运算符优先级

| Description    | Operator         | Associativity | Precedence |
| -------------- | ---------------- | ------------- | ---------- |
| Unary postfix  | e., e()          | None          | 16         |
| Unary prefix   | -e, !e           | None          | 16         |
| Multiplicative | \*, /, %         | Left          | 14         |
| Additive       | +, -             | Left          | 13         |
| Relational     | <, >, <=, >=, is | None          | 8          |
| Equality       | ==, !=           | None          | 7          |
| Logical and    | &&               | Left          | 6          |
| Logical or     | \|\|             | Left          | 5          |
| Assignment     | =                | Right         | 1          |
