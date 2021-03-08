# 河图脚本语言

河图的语言大体上和 typescript 比较接近，类型用冒号声明，语句结尾可以省略分号。河图的变量会从声明推断其类型，并且不会做自动转换。另外函数声明使用 fun 关键字。

## Hello World

```typescript
print('hello world!');
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

## 保留字

null, static, var, let, any, namespace, as, abstract, class, fun, construct, get, set, this, super, extends, implements, mixin, external, library, import, break, continue, for, in, if, else, return, while, when, is

## 注释

河图中的注释指以 '//' 开始的单行文本。或者以 '/\*' 包裹的多行文本。

```typescript
// This is a comment.
/* These are multi-line comments:
another line,
end here.*/
```

## 变量

河图中的变量声明以 var 或者 let 开头。类型和初始化都是可选项。类型默认为 any 。

```typescript
var person;
var name = 'naruto';
var year = 2020;
var fineStructureConstant: num = 1 / 137;
var isTimeTravelSuccessful: bool = true;
var gasGiants = ['Jupiter', 'Saturn'];
var skill: Map<String> = {
  tags: ['attack'],
  script: '//path/to/skill_script.ht',
};
```

在声明时，如果没有指定类型，以 var 声明的变量类型默认为 any，因此 var 声明的没有指定类型的变量可以使用其他类型的数据赋值。

```typescript
var name = 'naruto';
name = 2020;
```

而对于 let 开头的类型声明，以初始化值的类型为准。因此 let 声明的没有指定类型的变量，不能使用其它类型的数据赋值。

```typescript
let name = 'naruto';
// error!
// name = 2020
```

## 类型标记

类型标记时，虽然不需要事先声明。但只要加了标记，就会和初始化表达式的值类型进行匹配检查。

如果声明了一个不存在的类型标记的变量，但没有给初始化表达式，可能会导致这个变量无法使用。

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

函数声明可以使用 fun, get, set, construct 关键字。他们分别有不同的含义。
fun 关键字声明的函数，在没有指定返回值时，会默认指定返回值为 ANY，如果函数语句使用了 return 但没有附带表达式，则会返回 null，如果函数语句没有显式使用 return，则会返回最后执行的语句的表达式值。
get 和 set 是特殊的成员函数，此类声明会使对象在使用时好像具有了一个和函数声明名字相同的成员变量。
construct 是构造函数，构造函数不指定函数名字时，会默认给对象本身注册一个 call 方法，使得对象名字本身可以像函数那样调用，

```typescript
fun fib(n: int): num {
  if (n == 0 || n == 1) return n
  return fib(n - 1) + fib(n - 2)
}

var result = fib(10)
```

## 类

类声明可以使用 class, struct, interface 关键字。
class 声明的是普通的类，和其他面向对象语言类似。
struct 声明的是一个数据类，不能包含初始化语句。struct 类的对象可以被 struct 字面量赋值。并且 class 类声明时可以使用 mixin 直接将 struct 包含在自己内部。
interface 声明的是一个接口类，接口类中的函数不一定要提供函数定义。可以只包含声明，但如果这样做，任何继承了接口的类都必须对函数进行定义。

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
