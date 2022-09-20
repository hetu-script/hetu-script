# 内置类型

河图的基础类型本身就是 Dart 的对象。因此你可以直接在脚本中传递、修改这些对象，或者使用他们的 api：

- null
- bool
- num
- int
- double
- String
- Iterable
- List\<dynamic\>
- Set\<dynamic\>
- Map\<dynamic, dynamic\>
- Function (the Dart function object)

例如，我们可以在脚本中使用 dart 中的 Iterable 上提供的 map 接口：

```dart
final result = range(10).map((value) => 'row: ${value}')
```

注意：

1, 河图中浮点数类型名字使用 float，而不是 double，（实际类型的数值大小会根据平台而定）。

3, 河图中没有提供 Set 和 Map 的字面量写法。你需要通过普通构造函数的形式来创建他们的对象。

4, 河图中创建的 List/Set/Map 的泛型参数在 Dart 中全都是 dynamic 类型。

## 字符串

河图中的字符串类型名字使用 str，而不是 String。

### 字符串插值

字面量使用和 Javascript 相同的字符串插值写法。在 '${} 中可以写任何合法的表达式，表达式的值类型可以不是字符串，运行时将自动为其转换。

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

### 多行字符串

河图 0.4.0 版本之后的字符串，默认写法可以支持跨行。

```dart
var p = 'PPP'
var m = 'MMM'
final s = '

${
  p
  +
  m
}'
print(s)
print('a
multiline
string
')
```

和 Dart 的字符串插值的区别在于，即便括号中只有一个标识符，你也不能省略 '{}'。

## 大整数

河图中默认加入了 Dart 中的大整数类型。使用方法和 Dart 中相同：

```dart
final bi = BigInt.parse("9223372036854775807")
```

## Future

参考[这个页面](../future/readme.md)。
