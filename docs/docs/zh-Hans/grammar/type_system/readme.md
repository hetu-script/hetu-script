# 类型

**注意: 河图的类型系统的实现目前并不完整，目前只起到注解的作用，并不能提供静态分析等帮助。**

## 类型字面量

类型本身在河图中也是一个一等公民，可以作为表达式的值传递。

## 类型声明

类型声明以 type 作为关键字，用法类似变量声明，但类型声明必须提供一个初始化值。

```typescript
class Person {}

type PType = Person
type funcTypedef = fun(str) -> num
type structTypedef = {
  name: str,
  age: num,
}
```

## typeof

使用 **typeof** 关键字可以在运行时动态获取某个值对应的类型。

```typescript
fun main {
  // decalre a function typedef
  type funcTypedef = fun(str) -> num
  // assign a function to a value of a certain function type
  var numparse: funcTypedef = fun(value: str) -> num { return num.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = fun { return typeof numparse }
  var funcTypedef2 = getType()
  // use this new type
  var strlength: funcTypedef2 = fun(value: str) -> num { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

类型本身的类型永远是 'type'。

```typescript
type functype = ()->any
print(typeof functype) // type
>>>
```
