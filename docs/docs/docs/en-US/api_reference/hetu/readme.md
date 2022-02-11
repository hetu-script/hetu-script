# API for use in Hetu script

Most of the preincluded values' apis are kept the same name as the Dart SDK:
**num**, **int**, **double**, **bool**, **String**, **List**, **Set** and **Map**

There are also some hetu exclusive methods, like **List.random**, to get a random item out of a List.

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
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      var meaning
      eval("meaning = 'hello from a deeper dream!'")
      meaning
    ''');

  print(result);
}
```

## object

```javascript
abstract class object {
  external fun toString() -> str
}
```

## struct

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

## Math

```javascript
external class Math {
  static const e: num = 2.718281828459045

  static const pi: num = 3.1415926535897932external

  static fun radiusToSigma(radius: float) -> float

  // Box–Muller transform for generating normally distributed random numbers
  static fun gaussianNoise(mean: float, variance: float) -> float

  // Compute Perlin noise at coordinates x, y
  static fun perlinNoise(x: float, y: float) -> float

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

```javascript
external class Hash {

  static fun uid4(repeat: int) -> str

  static fun crc32b(data: str, [crc: str = 0]) -> str
}
```
