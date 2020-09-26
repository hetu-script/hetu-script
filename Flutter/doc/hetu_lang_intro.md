# 河图脚本语言特性概览

河图的语言大体上和 typescript 比较接近，类型用冒号声明，语句结尾可以省略分号。主要区别是河图的变量会从声明推断其类型，并且不会做自动转换。另外函数声明使用 fun 关键字。

## Hello World

```typescript
print("hello world!");
```

河图脚本文件可以使用三种不同的代码组织形式：脚本、库和程序

- 脚本:整个文件视为一个匿名函数的函数体，解释后立即执行。文件中可能包含变量和函数的声明语句、表达式语句和控制语句。要执行一个脚本，可以使用 hetu 命令行工具，并打开'-s'选项。或者在 Dart 中调用 Interpreter 对象的 eval 函数时，使用可选参数：ParseStyle style = ParseStyle.function
- 库：整个文件视为一个命名空间，解释后不一定立即执行，可能包含导入语句、变量、函数和类的声明语句。
- 程序：一种特殊的库，解释后会立即执行一个名为 main 的函数。

```typescript
// Define a function.
fun printNumber(aNumber: num) {
  // Print to console.
  print('The number is', aNumber)
}

// This is where the app starts executing.
fun main {
  var number = 42 // Declare and initialize a variable.
  printNumber(number) // Call a function.
}
```

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
  print("21st century");
} else if (year >= 1901) {
  print("20th century");
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
  return fib(n - 1) + fibonacci(n - 2);
}

var result = fibonacci(10);
```

## 保留字

null, static, var, let, any, namespace, as, abstract, class, fun, construct, get, set, this, super, extends, implements, mixin, external, library, import, break, continue, for, in, if, else, return, while, when, is

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
