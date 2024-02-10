# 语法概要

河图的语法类似 typescript/kotlin/swift 等现代语言，通常只需要了解一些关键点即可直接上手使用：

## 声明以关键字开头

河图中所有的声明都以关键字开头。例如：

**var, final, const, function, constructor, get, set, class, type**

## 分号可选

河图中的分号是可选的。大多数时候编译器和解释器会自动分清语句的间隔。

## 类型注解

类型注解是可选的，以冒号形式写在标识符后面。

## 模式匹配

河图使用 [switch 语句](control_flow/readme.md#switch) 进行简单的模式匹配。

## 注释

普通注释：

```typescript
// This is a comment.
/* These are multi-line comments:
another line.*/
```

文档注释：

```typescript
/// This is a documentation comment
function myFunc() -> int {
  ...
}
```

## 私有标识符

以 '\_' 开头的标识符作为私有标识符。只能在其声明的命名空间才可以访问。

```dart
class Person {
  var _name
  constructor (name) {
    _name = name
  }
  function greeting {
    print('Hi, I\'m ', _name)
  }
}
final p = Person('jimmy')
// print(p._name) // Error!
p.greeting()
```

## 表达式和语句

河图中，所有语句都是表达式，因此也具有值。

例如变量声明和变量赋值，都会返回变量的值。对于下面的代码

```dart
if (a = fetch()) {
  // ...
}
```

如果 a 的值可以[隐式转换](strict_mode/readme.md#布尔值)为真，则 if 表达式将会执行。

# 代码块

河图中的代码块会返回最后一个表达式的值：

```javascript
function test(n) {
  var x = n * 2;
}
```

上述函数的返回值就是 n \* 2
