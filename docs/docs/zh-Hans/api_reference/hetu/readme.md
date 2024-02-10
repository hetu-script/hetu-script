# 河图中提供的 API

河图中的一些基础类型本身是 Dart 类型，同时也默认绑定了大多数 Dart 中的 api。例如下面这些类型和其对象都可以在脚本中直接使用：**num**, **int**, **double**, **bool**, **String**, **List**, **Set**, **Map**。

例如，我们可以在脚本中使用 dart 中的列表上提供的 map 接口：

```dart
final result = range(10).map((value) => 'row: ${value}')
```

## 全局函数

下面是一些脚本中可以直接使用的函数：

```javascript
external function print(... args: any)

external function stringify(obj: any)

external function jsonify(obj)

external function range(startOrStop: num, [stop: num, step: num]) -> Iterable
```

### eval()

此外，和 Javascript 一样，脚本中包含一个用以解释自己的接口 **eval()**：

```dart
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      final meaning = eval("6 * 7")
      meaning
    ''');

  print(result);
}
```

## 对象字面量

河图中包含类似 Javascript 的对象字面量语法。并且也实现了基本的原型链。

河图中所有的对象字面量都有一个原型对象，并且在这个原型对象上预先定义了一些常用接口：

````typescript

struct Prototype {
  /// Create a struct from a dart Json data
  /// Usage:
  /// ```
  /// var obj = Prototype.fromJson(jsonDataFromDart)
  /// ```
  external static function fromJson(data) -> {}

  /// Get the List of the keys of this struct
  external get keys -> List

  /// Get the List of the values of this struct
  /// The values are copied,
  /// you cannot modify the struct in this way
  external get values -> List

  /// Check if this struct has a key in its own fields.
  external function containsKey(key: str) -> bool

  /// Check if this struct has a key
  /// in its own fields or its prototypes' fields.
  external function contains(key: str) -> bool

  /// Check if this struct is empty.
	external get isEmpty -> bool

  /// Check if this struct is not empty.
	external get isNotEmpty -> bool

  /// Get the number of the members of this struct.
  /// Will not include the members of its prototypes.
	external get length -> int

  /// Create a new struct form deepcopying this struct
  external function clone() -> {}

  /// Create dart Json data from this struct
  function toJson() -> Map => jsonify(this)

  function toString() -> str => stringify(this)
}
````

大多数上面这些方法都可以直接在对象上调用。例如：

```javascript
final obj = { a: 42 }

obj.contains('a') // true
```

对于 static 方法，需要通过原型的名字来调用：

```dart
final book = Prototype.fromJson(data);
```

## Math

脚本中提供了 Dart 中 Random 对象的绑定，用来生成随机数，并且提供了一些额外的辅助 api，例如获取随机颜色，以及获取一个列表中的随机对象等。

脚本中将 Dart 的 Math 库，绑定为了一个静态类，内置了一些数学相关的常数和接口。

```javascript
external class Random {

  constructor ([seed: int])

  function nextBool -> bool

  function nextInt(max: int) -> int

  function nextDouble() -> float

  function nextColorHex({hasAlpha: bool = false}) -> str

  function nextBrightColorHex({hasAlpha: bool = false}) -> str

  function nextIterable(list: Iterable) -> any

  function shuffle(list: Iterable) -> Iterable
}

external class Math {
  static const e: float = 2.718281828459045

  static const pi: float = 3.1415926535897932

  /// Convert [radians] to degrees.
  static function degrees(radians)

  /// Convert [degrees] to radians.
  static function radians(degrees)

  static function radiusToSigma(radius: float) -> float

  /// Box–Muller transform for generating normally distributed random numbers between [min : max].
  static function gaussianNoise(mean: float, standardDeviation: float, {min: float, max: float, randomGenerator}) -> float

  /// Noise generation function provided by [fast_noise](https://pub.dev/packages/fast_noise) package.
  /// Noise types: perlin, perlinFractal, cubic, cubicFractal
  static function noise2d(size, {seed, noiseType = 'cubic', frequency = 0.01})

  /// Return the smaller value between a & b.
  /// If one of them is null, return the other value.
  static function min(a, b)

  /// Return the greater value between a & b.
  /// If one of them is null, return the other value.
  static function max(a, b)

  static function sqrt(x: num) -> num

  static function pow(x: num, exponent: num) -> num

  static function sin(x: num) -> num

  static function cos(x: num) -> num

  static function tan(x: num) -> num

  static function exp(x: num) -> num

  static function log(x: num) -> num

  static function parseInt(source: str, {radix: int?}) -> num

  static function parseDouble(source: str) -> num

  static function sum(list: List<num>) -> num

  static function checkBit(index: int, check: int) -> bool

  static function bitLS(x: int, distance: int) -> bool

  static function bitRS(x: int, distance: int) -> bool

  static function bitAnd(x: int, y: int) -> bool

  static function bitOr(x: int, y: int) -> bool

  static function bitNot(x: int) -> bool

  static function bitXor(x: int, y: int) -> bool
}

```

## Hash

脚本中定义了一个静态类 Hash ，内置了一些字符串加密相关的接口。

```javascript
external class Hash {

  static function uid4([repeat: int?]) -> str

  static function crcString(data: str, [crc: str = 0]) -> str

  static function crcInt(data: str, [crc: str = 0]) -> int
}

```
