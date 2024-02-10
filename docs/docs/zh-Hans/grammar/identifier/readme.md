# 标识符

标识符指变量、函数、类的名字。

河图中的标识符可以使用任何语言中的文字，以及 '\_' 和 '$' 这两个特殊符号。

但你可以通过 '``' 符号（键盘左上角 1 左边的按键）来定义一个标识符字面量。此时你将不受上述限制，可以使用任何字符，包括 emoji 等 unicode 字符。

```dart
var obj = {
  `name-#42🍎`: 'aleph' // it's legal for a field name.
}

print(obj.`name-#42🍎`) // 'aleph'
```

## 关键字

河图的保留关键字不能用作普通的标识符。下面是完整的关键字列表：

**null, true, false, void<sup>1</sup>, type<sup>1</sup>, import<sup>1</sup>, export<sup>1</sup>, from<sup>1</sup>, any<sup>1</sup>, unknown<sup>12</sup>, never<sup>12</sup>, var, final, const, def<sup>2</sup>, delete<sup>2</sup>, type<sup>1</sup>, typeval, typeof, decltypeof, namespace, class, enum, function, struct, this, super, abstract, override<sup>2</sup>, external, static, extends<sup>1</sup>, implements<sup>12</sup>, with<sup>12</sup>, new, constructor, factory, get, set, async<sup>2</sup>, await<sup>2</sup>, break, continue, return, for, in, of<sup>1</sup>, if, else, while, do, when, is, as**

1: 这些关键字是 “上下文” 关键字，只有在特定场合使用。因此可以用作普通的标识符。

2: 这些关键字目前没有任何意义，只是为了未来的语言功能开发提前保留的。
