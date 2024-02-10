# 类型系统

**注意: 河图的类型系统的实现目前并不完整，目前只起到注解的作用，并不能提供静态分析等帮助。**

## 类型作为值

类型本身在河图中也是一个一等公民，可以作为表达式的值传递。

如果你想要在值表达式中获取一个类型的值，你必须使用 `type` 关键字：

```typescript
function checkType(t: type) {
  switch (t) {
    typeval {} => {
      print('a structural type')
    }
    // the function won't match here
    // you have to use the exact type value here for match
    typeval ()->any => {
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
type FuncTypedef = (str) -> num
type StructTypedef = {
  name: str,
  age: num,
}
```

河图中目前包括四种类型：

### 内置类型

这些类型通常都是关键字：

#### any

等同于 Dart 中的 dynamic，任何值都可以赋值给一个 any 类型。

**void, never & unknown 这三个关键字代表了其他的一些内置类型，但他们需要在静态类型检查阶段发挥作用，因此在目前版本中尚未被完全支持。**

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
  name: str;
  age: num;
};
```

### 函数类型

函数类型的写法类似函数声明，但它不能像函数声明一样省略某些部分。

它一定要包含一个圆括号括起来的参数列表（但可以为空），以及一个单箭头后面的返回值类型。

```typescript
type FuncTypedef = (str) -> num
```

## 使用 is 在运行时动态检查类型

使用 **is** 关键字可以在运行时动态检查某个值对应的类型。

```typescript
function doSomething(value) {
  if (value is str) {
    print('A String!')
  } else if (value is num) {
    print('A Number!')
  } else {
    print('Unknown type!')
  }
}
```

## 使用 typeof 在运行时动态获取类型

使用 **typeof** 关键字可以在运行时动态获取某个值对应的类型。

```typescript
function main {
  // decalre a function typedef
  type FuncTypedef = function(str) -> num
  // assign a function to a value of a certain function type
  var numparse: FuncTypedef = function(value: str) -> num { return num.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = function { return typeof numparse }
  var FuncTypedef2 = getType()
  // use this new type
  var strlength: FuncTypedef2 = function(value: str) -> num { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

类型本身的类型永远是 'type'。

```typescript
type Functype = ()->any
print(typeof (typeof functype)) // type
```
