# API for use in Hetu script

Most of the preincluded values' apis are kept the same name as the Dart SDK:
**number**, **int**, **double**, **bool**, **String**, **List**, **Set** and **Map**

And most of the common apis from Dart are already binded in the script.

For instance, we can use the map api just like in Dart on an Iterable:

```dart
final result = range(10).map((value) => 'row: ${value}')
```

## Global functions

```javascript
external function print(... args: any)

external function stringify(obj: any)

external function jsonify(obj)

external function range(startOrStop: number, [stop: number, step: number]) -> Iterable
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

struct Object {
  /// Create a struct from a dart Json data
  /// Usage:
  /// ```
  /// var obj = Object.fromJson(jsonDataFromDart)
  /// ```
  external static function fromJson(data) -> {}

  /// Get the List of the keys of this struct
  external get keys -> List

  /// Get the List of the values of this struct
  /// The values are copied,
  /// you cannot modify the struct in this way
  external get values -> List

  /// Check if this struct has a key in its own fields.
  external function containsKey(key: string) -> bool

  /// Check if this struct has a key
  /// in its own fields or its prototypes' fields.
  external function contains(key: string) -> bool

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
  function toJSON() -> Map => jsonify(this)

  function toString() -> string => stringify(this)
}
````

All struct object can use those pre-defined methods defined on this root prototype:

```javascript
final obj = { a: 42 }

obj.contains('a') // true
```

For static methods, you need to explicitly call by the prototype:

```dart
final book = Object.fromJson(data);
```

## Math

The script provides the binding of Random object in Dart. And there's some original api on it, for example we can easily create random colors.

The script combined the math library into a static class.

```javascript
external class Random {

  constructor ([seed: int])

  function nextBool -> bool

  function nextInt(max: int) -> int

  function nextDouble() -> float

  function nextColorHex({hasAlpha: bool = false}) -> string

  function nextBrightColorHex({hasAlpha: bool = false}) -> string

  function nextIterable(list: Iterable) -> any

  function shuffle(list: Iterable) -> Iterable
}

external class Math {
  static const e: number = 2.718281828459045

  static const pi: number = 3.1415926535897932

  /// Convert [radians] to degrees.
  static function degrees(radians)

  /// Convert [degrees] to radians.
  static function radians(degrees)

  static function radiusToSigma(radius: float) -> float

  // Box–Muller transform for generating normally distributed random numbers between [min : max].
  static function gaussianNoise(mean: float, standardDeviation: float, {min: float, max: float, randomGenerator}) -> float

  // Noise generation function provided by [fast_noise](https://pub.dev/packages/fast_noise) package.
  // Noise types: perlin, perlinFractal, cubic, cubicFractal
  static function noise2d(width, height, {seed, noiseType = 'cubic', frequency = 0.01})

  static function min(a, b)

  static function max(a, b)

  static function sqrt(x: number) -> number

  static function pow(x: number, exponent: number) -> number

  static function sin(x: number) -> number

  static function cos(x: number) -> number

  static function tan(x: number) -> number

  static function exp(x: number) -> number

  static function log(x: number) -> number

  static function parseInt(source: string, {radix: int?}) -> number

  static function parseDouble(source: string) -> number

  static function sum(list: List<number>) -> number

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

Some utility method about hash & crypto are defined in the static class Hash.

```javascript
external class Hash {

  static function uid4([repeat: int?]) -> string

  static function crcString(data: string, [crc: string = 0]) -> string

  static function crcInt(data: string, [crc: string = 0]) -> int
}
```
