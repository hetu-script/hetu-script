# 特殊语法和操作符

## 展开语法

你可以在三种场合使用展开（'...'）：

### 函数调用时的参数

你可以将一个 Iterable 展开后作为位置参数传入一个函数调用的参数列表。

```javascript
function someFunc(a, b) {
  print(a + b);
}
var list = [5, 6];
someFunc(...list); // same to 'someFunc(5, 6)'
```

### 列表字面量

你可以在定义一个列表字面量时展开另一个列表，将其成员填充进去。

```javascript
var list = [5, 6];
var ht = [1, 2, ...[3, 4], ...list]; // same to [1, 2, 3, 4, 5, 6]
```

### 结构体（struct）字面量

你可以在定义一个结构体字面量时展开另一个结构体，将其成员填充进去。

```javascript
var name = {
  familyName: "Hord",
  firstName: "Luk",
};
var job = "wood cutter";
var person = {
  ...name,
  age: 23,
};
// same to:
// {
//   familyName: 'Hord',
//   firstName: 'Luk',
//   age: 23,
//   job: 'wood cutter'
// }
```

## 空值检查

目前河图没有使用 “空安全” 的设定。但你可以使用一些语法来进行快速的空值检查：

```dart
var a // a is null
// Nullable member get:
final value = a?.value // value is null and we won't get errors
final result = a?() // nullabla function call
// If null then get another value
final text = a ?? 'hi!' // text is 'hi!'
// If null then assign
a ??= 42
print(a) // a is 42 now
```

空值检查具有传递性。'?'之后的所有可以进行控制检查的表达式都会默认允许空值。

```dart
var a // a is null
final value = a?.collection[0].value() // value is null and we won't get errors
```

## new 操作符

new 操作符是一种显示调用构造函数的方法。和普通构造函数的区别在于 new 操作符支持无参数列表（连括号也不用写）方式构造新对象。

```dart
struct P {
  var name = 'Jimmy'
}
final p = new P
print(p)
```

## 操作符优先级

河图中的操作符优先级是 Dart 的操作符优先级表的一个子集。

| Description    | Operator                           | Associativity | Precedence |
| :------------- | :--------------------------------- | :-----------: | :--------: |
| Unary postfix  | e., e?., e++, e--, e1[e2], e()     |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e, await e          |     None      |     15     |
| Multiplicative | \*, /, ~/, %                       |     Left      |     14     |
| Additive       | +,                                 |     Left      |     13     |
| Relational     | <, >, <=, >=, as, is, is!, in, in! |     None      |     8      |
| Equality       | ==, !=                             |     None      |     7      |
| Logical AND    | &&                                 |     Left      |     6      |
| Logical Or     | \|\|                               |     Left      |     5      |
| If null        | \?\?                               |     Left      |     4      |
| Conditional    | e1 ? e2 : e3                       |     Right     |     3      |
| Assignment     | =, \*=, /=, ~/=, +=, -=, ??=       |     Right     |     1      |
