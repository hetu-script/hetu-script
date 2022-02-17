# 内置类型

河图的基础类型本身就是 Dart 的对象。因此你可以直接在脚本中传递、修改这些对象，或者使用他们的 api：

- null
- bool
- num
- int
- double
- String
- List\<dynamic\>
- Set\<dynamic\>
- Map\<dynamic, dynamic\>
- Function (the Dart function object)

注意：

1, 河图脚本中的浮点数类型名字使用 float，而不是 double，（实际类型的数值大小会根据平台而定）。

2, 河图中没有提供 Set 和 Map 的字面量写法。你需要通过普通构造函数的形式来创建他们的对象。

3, 河图中创建的 List/Set/Map 的泛型参数在 Dart 中全都是 dynamic 类型。

## 大整数

河图中默认加入了 Dart 中的大整数类型。使用方法和 Dart 中相同：

```dart
final bi = BigInt.parse("9223372036854775807")
```

## Future

参考[这个页面](../future/readme.md)。
