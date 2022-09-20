# API for use in Hetu script

Most of the preincluded values' apis are kept the same name as the Dart SDK:
**num**, **int**, **double**, **bool**, **String**, **List**, **Set** and **Map**

And most of the common apis from Dart are already binded in the script.

For instance, we can use the map api just like in Dart on an Iterable:

```dart
final result = range(10).map((value) => 'row: ${value}')
```

## Global functions

```javascript
external fun print(... args: any)

external fun stringify(obj: any)

external fun jsonify(obj)

external fun range(startOrStop: num, [stop: num, step: num]) -> Iterable
```

### eval()

You can use **eval** method within the script itself to evaluate a string, just like in Javascript:

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

## struct

Hetu have a prototyped based struct object like the literal object syntax in Javascript.

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

All struct object can use those pre-defined methods defined on this root prototype:

```javascript
final obj = { a: 42 }

obj.contains('a') // true
```

For static methods, you need to explicitly call by the prototype:

```dart
final book = prototype.fromJson(data);
```

## Math

The script provides the binding of Random object in Dart. And there's some original api on it, for example we can easily create random colors.

The script combined the math library into a static class.

```javascript
external class Random {

  construct ([seed: int])

  fun nextBool -> bool

  fun nextInt(max: int) -> int

  fun nextDouble() -> float

  fun nextColorHex({hasAlpha: bool = false}) -> str

  fun nextBrightColorHex({hasAlpha: bool = false}) -> str

  fun nextIterable(list: Iterable) -> any

  fun shuffle(list: Iterable) -> Iterable
}

external class Math {
  static const e: num = 2.718281828459045

  static const pi: num = 3.1415926535897932

  /// Convert [radians] to degrees.
  static fun degrees(radians)

  /// Convert [degrees] to radians.
  static fun radians(degrees)

  static fun radiusToSigma(radius: float) -> float

  // Box–Muller transform for generating normally distributed random numbers between [min : max].
  static fun gaussianNoise(mean: float, standardDeviation: float, {min: float, max: float, randomGenerator}) -> float

  // Noise generation function provided by [fast_noise](https://pub.dev/packages/fast_noise) package.
  // Noise types: perlin, perlinFractal, cubic, cubicFractal
  static fun noise2d(size, {seed, noiseType = 'cubic', frequency = 0.01})

  static fun min(a, b)

  static fun max(a, b)

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

  static fun checkBit(index: int, check: int) -> bool

  static fun bitLS(x: int, distance: int) -> bool

  static fun bitRS(x: int, distance: int) -> bool

  static fun bitAnd(x: int, y: int) -> bool

  static fun bitOr(x: int, y: int) -> bool

  static fun bitNot(x: int) -> bool

  static fun bitXor(x: int, y: int) -> bool
}
```

## Hash

Some utility method about hash & crypto are defined in the static class Hash.

```javascript
external class Hash {

  static fun uid4([repeat: int?]) -> str

  static fun crcString(data: str, [crc: str = 0]) -> str

  static fun crcInt(data: str, [crc: str = 0]) -> int
}
```
