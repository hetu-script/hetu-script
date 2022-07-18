# 河图中提供的 API

河图中的一些基础类型本身是 Dart 类型，同时也默认绑定了大多数 Dart 中的 api。例如下面这些类型和其对象都可以在脚本中直接使用：**num**, **int**, **double**, **bool**, **String**, **List**, **Set**, **Map**。

为了方便，河图中也添加了一些额外的接口，例如 **Iterable.random** 用以获得某个数组中的一个随机对象。

## 全局函数

下面是一些脚本中可以直接使用的函数：

```javascript
external fun print(... args: any)

external fun stringify(obj: any)

external fun jsonify(obj)

external fun range(startOrStop: num, [stop: num, step: num]) -> Iterable
```

### eval()

此外，和 Javascript 一样，脚本中包含一个用以解释自己的接口 **eval()**：

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      var meaning
      eval("meaning = 'hello from a deeper dream!'")
      meaning
    ''');

  print(result);
}
```

## 对象字面量

河图中包含类似 Javascript 的对象字面量语法。并且也实现了基本的原型链。

河图中所有的对象字面量都有一个原型对象，并且在这个原型对象上预先定义了一些常用接口：

````typescript

struct prototype {
  /// Create a struct from a dart Json data
  /// Usage:
  /// ```
  /// var obj = prototype.fromJson(jsonDataFromDart)
  /// ```
  external static fun fromJson(data) -> {}

  /// Get the List of the keys of this struct
  external get keys -> List

  /// Get the List of the values of this struct
  /// The values are copied,
  /// you cannot modify the struct in this way
  external get values -> List

  /// Check if this struct has a key in its own fields.
  external fun containsKey(key: str) -> bool

  /// Check if this struct has a key
  /// in its own fields or its prototypes' fields.
  external fun contains(key: str) -> bool

  /// Check if this struct is empty.
	external get isEmpty -> bool

  /// Check if this struct is not empty.
	external get isNotEmpty -> bool

  /// Get the number of the members of this struct.
  /// Will not include the members of its prototypes.
	external get length -> int

  /// Create a new struct form deepcopying this struct
  external fun clone() -> {}

  /// Create dart Json data from this struct
  fun toJson() -> Map => jsonify(this)

  fun toString() -> str => stringify(this)
}
````

大多数上面这些方法都可以直接在对象上调用。例如：

```javascript
final obj = { a: 42 }

obj.contains('a') // true
```

对于 static 方法，需要通过原型的名字来调用：

```dart
final book = prototype.fromJson(data);
```

## Math

脚本中定义了一个静态类 Math ，内置了一些数学相关的常数和接口。

```javascript
external class Math {
  static const e: num = 2.718281828459045

  static const pi: num = 3.1415926535897932external

  static fun radiusToSigma(radius: float) -> float

  // Box–Muller transform for generating normally distributed random numbers
  static fun gaussianNoise(mean: float, variance: float) -> float

  static fun min(a, b)

  static fun max(a, b)

  static fun random() -> num

  static fun randomInt(max: num) -> num

  static fun sqrt(x: num) -> num

  static fun pow(x: num, exponent: num) -> num

  static fun sin(x: num) -> num

  static fun cos(x: num) -> num

  static fun tan(x: num) -> num

  static fun exp(x: num) -> num

  static fun log(x: num) -> num

  static fun parseInt(source: str, {radix: int?}) -> num

  static fun parseDouble(source: str) -> num

  static fun sum(list: List<num>) -> num

  static fun checkBit(index: num, check: num) -> bool

  static fun bitLS(x: num, distance: num) -> bool

  static fun bitRS(x: num, distance: num) -> bool

  static fun bitAnd(x: num, y: num) -> bool

  static fun bitOr(x: num, y: num) -> bool

  static fun bitNot(x: num) -> bool

  static fun bitXor(x: num, y: num) -> bool
}
```

## Hash

脚本中定义了一个静态类 Hash ，内置了一些字符串加密相关的接口。

```javascript
external class Hash {

  static fun uid4(repeat: int) -> str

  static fun crcString(data: str, [crc: str = 0]) -> str
}
```
