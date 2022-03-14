# 变量

变量声明以 **var, final, late, const** 开头，类型注解和初始化值表达式是可选的。除了 var 之外的声明，都无法修改它的值。

```dart
var person
var fineStructureConstant: num = 1 / 137
final isTimeTravelSuccessful: bool = true
final skill: List = ['attack', 'defense']
```

## 常量

对于数字和字符串字面量，可以使用 const 声明来获得一个常量。此种类型的常量将会在编译前求值，因此在运行时会稍微提高效率。

```dart
const pi = 3.1415926
```

默认情况下，不支持表达式的运算，即便表达式中的标识符也是常量。因此一个 const 声明的初始化值如果是表达式，则等同于 final 声明。因为表达式的值在运行时才会运算出来。

这个功能可以在河图 0.4.0 以上的版本中通过编译选项打开。

```dart
// 默认情况下等同于 final pi2 = 3.1415926 * 2
const pi2 = 3.1415926 * 2
```

## 延迟赋值

对于 var 和 final，在没有初始化时直接使用这个标识符，将会得到 null 值。

你可以使用 late 来禁止访问一个未初始化的常量。

```dart
late a
// print(a) // Error: [a] is not initialized yet.
a = 42
print(a)
a = 'dragon' // Error: [a] is immutable.
```

## 删除

你可以通过 delete 关键字来删除一个变量声明。

```dart
var a = 42
delete a
print(a) // error: a is undefined!
```

但你不能删除一个 class 上的成员。

## 解构声明

在河图中，为了表达清晰的目的，**你不能像 C++/Java 那样在一个声明中写多个标识符**。

```dart
var a,b,c// error
```

但你可以使用类似 Javascript/Kotlin 的结构声明。这种声明必须提供一个 Iterable 或者一个 struct/Map 作为初始化值。

```javascript
var [a, b, c] = [1, 2, 3]; // a = 1, b = 2, c = 3
var { x, y } = { x: 6, y: 7 }; // x = 6, y = 7
```

当你解构声明的值来自数组时，你可以使用 '\_' 关键字，忽略某个位置的变量。

```javascript
var [_, _, z] = [1, 2, 3]; // z = 3
```

注意：解构声明不可以[延迟初始化](../../guide/implementation_detail/readme.md#延迟初始化)，因此只能在函数体或者 **ResourceType.hetuScript** 类型的代码文件中使用。
