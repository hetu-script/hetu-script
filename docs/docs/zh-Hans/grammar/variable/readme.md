# 变量

变量声明以 **var, final, late, const** 开头，类型注解和初始化值表达式是可选的。除了 var 之外的声明，都无法修改它的值。

```dart
var person
var fineStructureConstant: number = 1 / 137
final isTimeTravelSuccessful: bool = true
final skill: List = ['attack', 'defense']
```

## 常量

使用 `const` 关键字可以声明一个编译时常量。支持四种常量类型：布尔、整数、浮点数和字符串。常量值存储在全局去重表中以提升性能 — 相同的常量值共享同一存储。

```dart
const pi = 3.1415926
const name = 'Hetu'
const isReady = true
const answer = 42
```

默认情况下，常量表达式运算不会启用。如果 `const` 声明的初始化值是一个表达式，则行为等同于 `final` 声明。

可以通过在 Hetu 配置中设置 `computeConstantExpression: true` 来启用常量表达式计算（0.4.0 版本之后可用）：

```dart
// 启用 computeConstantExpression 时，编译时计算：
const pi2 = 3.1415926 * 2

// 未启用时（默认），等价于：
// final pi2 = 3.1415926 * 2
```

**`const` 与 `final` 的区别：**
- `const` 值是编译时常量，存储在去重的全局表中。
- `final` 值是运行时赋值后不可变的变量。
- `const` 只能持有字面量值（默认）；`final` 可以持有任何运行时的值。

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

### 使用 `_` 忽略值

从列表/Iterable 解构时，使用 `_` 跳过不需要的值：

```javascript
var [_, _, z] = [1, 2, 3]; // z = 3
```

### 从 struct 解构

从 struct 解构时，变量名必须与字段名匹配：

```javascript
final obj = { a: 6, b: 7 }
final { a, b } = obj  // a = 6, b = 7
```

### 要求

解构声明**必须**有一个初始化值，并且必须立即初始化。只能在脚本体（`ResourceType.hetuScript`）或函数体中使用，不能在类级声明中使用。
