# 类型系统

河图的类型系统在运行时支持四种类型：内置类型、标称类型（类名）、结构类型（鸭子类型）和函数类型。运行时类型检查（`is`、`is!`、`as`、`typeof`、`decltypeof`）已完整支持。静态类型分析可通过在 Hetu 配置中启用 `doStaticAnalysis` 来单独使用——分析器正在积极开发中。

## 类型作为值

类型本身在河图中也是一个一等公民，可以作为表达式的值传递。

如果你想要在值表达式中获取一个类型的值，你必须使用 `type` 关键字：

```typescript
function checkType(t: type) {
  switch (t) {
    typeval {} : {
      print('a structural type')
    }
    // the function won't match here
    // you have to use the exact type value here for match
    typeval ()->any : {
      print('a function type')
    }
  }
}
```

## 类型声明

类型声明以 `type` 作为关键字，用法类似变量声明，但类型声明必须提供一个初始化值。

```typescript
class Person {}

type PType = Person
type FuncTypedef = (string) -> number
type StructTypedef = {
  name: string,
  age: number,
}
```

河图中目前包括四种类型：

### 内置类型

这些类型通常都是关键字：

#### any

等同于 Dart 中的 dynamic，任何值都可以赋值给一个 any 类型。

**void, never & unknown 也属于内置类型。`void` 表示无返回值。`never` 是底部类型（所有类型的子类型）。`unknown` 是未分析代码的顶部类型。它们主要用于静态类型检查，但在运行时也是有效的类型值。**

### 标称类型（nominal type）

class 关键字声明的类的名字，被称作标称类型：

```typescript
class Person {}
```

### 结构类型（structural type）

结构类型是一种[鸭子类型](https://zh.wikipedia.org/wiki/%E9%B8%AD%E5%AD%90%E7%B1%BB%E5%9E%8B)的实现. 和 [struct](../struct/readme.md) 配合使用。

它的语法类似于 struct 字面量，但在键名冒号后面跟着的一定是一个类型，而不是表达式。

```typescript
type StructTypedef = {
  name: string;
  age: number;
};
```

### 函数类型

函数类型的写法类似函数声明，但它不能像函数声明一样省略某些部分。

它一定要包含一个圆括号括起来的参数列表（但可以为空），以及一个单箭头后面的返回值类型。

```typescript
type FuncTypedef = (string) -> number
```

## 使用 is / is! 在运行时动态检查类型

使用 **is** 关键字可以在运行时动态检查某个值对应的类型。

使用 **is!** 检查某个值不属于某个类型。

```typescript
function doSomething(value) {
  if (value is string) {
    print('A String!')
  } else if (value is number) {
    print('A Number!')
  } else if (value is! bool) {
    print('Not a Boolean!')
  } else {
    print('Unknown type!')
  }
}
```

## 使用 as 进行类型转换

使用 **as** 在运行时将值转换为特定类型。如果转换无效（值不属于目标类型），将抛出运行时错误。

```typescript
class Super3 {
  var name = 'Super'
}
class Extend3 extends Super3 {
  var name = 'Extend'
}
var a = Extend3()
var b = a as Super3
print(b.name) // 'Extend' — b 仍然引用同一个 Extend3 实例
```

## 使用 typeof 在运行时动态获取类型

使用 **typeof** 关键字可以在运行时动态获取某个值对应的类型。

```typescript
function main {
  // decalre a function typedef
  type FuncTypedef = function(string) -> number
  // assign a function to a value of a certain function type
  var numparse: FuncTypedef = function(value: string) -> number { return number.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = function { return typeof numparse }
  var FuncTypedef2 = getType()
  // use this new type
  var strlength: FuncTypedef2 = function(value: string) -> number { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

类型本身的类型永远是 'type'。

```typescript
type Functype = ()->any
print(typeof (typeof functype)) // type
```

## 使用 decltypeof 获取声明类型

使用 **decltypeof** 关键字获取变量的声明类型注解，而非其当前值的运行时类型。这在需要在运行时检查类型注解时很有用。

```typescript
class Person {}
var p: Person = Person()
print(decltypeof p) // Person （声明类型）
print(typeof p)     // Person （运行时类型 — 此例中相同）
```
