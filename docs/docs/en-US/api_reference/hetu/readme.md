# API for use in Hetu script

The preincluded value types are backed by real Dart objects, and most of their Dart SDK methods are bound in the script: **number**, **integer**, **float**, **bool**, **string**, **List**, **Set**, **Map**, **Iterable**, **BigInt**.

For instance, we can use the `map` API just like in Dart on an Iterable:

```dart
final result = range(10).map((value) => 'row: ${value}')
```

Many of these APIs also have **JavaScript-style aliases** (`push`, `filter`, `padStart`, `Math.PI`, `Promise.resolve`, ...). See the [JavaScript Developers guide](/en-US/guide/javascript/) for the full alias table and the semantic differences to watch out for.

Type aliases provided for convenience: `num` (= `number`), `int` (= `integer`), `double` (= `float`), `str` / `String` (= `string`), `Number` (= `number`), `Promise` (= `Future`).

## Global functions and values

```javascript
external function print(... args: any)
external function range(startOrStop: number, [stop: number, step: number]) -> Iterable
external function eval(code: string)
external function require(path: string)
external function help(id: string)
external function parseInt(source: string, [radix: integer?]) -> number
external function parseFloat(source: string) -> number
```

- `print`: stringify and print one or several objects to standard output.
- `range`: create an iterable of numbers, with an optional step.
- `eval`: dynamically evaluate a string of Hetu source code.
- `require`: dynamically import a source on the current source context, returns its namespace.
- `help`: print the documentation of an identifier, e.g. `help(require)`.
- `parseInt` / `parseFloat`: parse numbers from strings (Dart `tryParse` semantics).

Also available in the global scope:

- `global` / `globalThis`: the global namespace object.
- `NaN`, `Infinity`: aliases of `float.nan` and `float.infinity`.
- `isNaN(x)`, `isFinite(x)`: wrappers of the corresponding instance getters, without implicit conversion.
- `kHetuVersion`: the language version string.

### eval()

You can use **eval** within the script itself to evaluate a string, just like in JavaScript:

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

## struct Object

Hetu has a prototype-based struct object with literal syntax similar to JavaScript objects. All structs share the root prototype `Object`, which provides the following members:

```typescript
struct Object {
  /// Create a struct from a Dart JSON map.
  external static function fromJSON(data) -> {}

  /// Assign source object's members to target.
  external static function assign(target, source)

  /// Assign source object's members to target only when the key is absent.
  external static function merge(target, source)

  /// Check membership, including prototypes.
  external function contains(key: string) -> bool

  /// Check membership of the struct's own fields only.
  external function containsKey(key: string) -> bool

  external get keys -> Iterable
  external get values -> Iterable
  external get isEmpty -> bool
  external get isNotEmpty -> bool
  external get length -> integer

  /// Remove a field by key.
  external function remove(key: string) -> any

  /// Deep copy this struct.
  external function clone() -> {}

  function hasOwnProperty(key: string) => this.containsKey(key)
  static function hasOwn(object, key: string) => object.containsKey(key)

  /// A list of MapEntry for the struct's own fields.
  static function entries(object)

  /// Create a struct from MapEntry items or [key, value] pairs.
  static function fromEntries(entries)

  function toJSON() -> Map => JSON.jsonify(this)
  function toString() -> string => JSON.stringify(this)

  /// Deep-copy or convert the argument into a struct.
  /// (Different from JavaScript's prototype-based Object.create.)
  function create(data)
}
```

Instance members can be called on any struct directly:

```javascript
final obj = { a: 42 }
obj.contains('a') // true
```

Static methods are called through the prototype name:

```dart
final book = Object.fromJSON(data);
```

## Math

The `Math` static class combines Dart's `dart:math` library, JavaScript-style aliases, and some Hetu-specific helpers.

Constants: `e`, `pi`, `ln2`, `ln10`, `log2e`, `log10e`, `sqrt2`, `sqrt1_2`, and the uppercase aliases `E`, `PI`, `LN2`, `LN10`, `LOG2E`, `LOG10E`, `SQRT2`, `SQRT1_2`.

```javascript
abstract class Math {
  external static function random()
  external static function min(... values: number) -> number
  external static function max(... values: number) -> number
  external static function pow(x: number, exponent: number) -> number
  external static function sin(x: number) -> number
  external static function cos(x: number) -> number
  external static function tan(x: number) -> number
  external static function asin(x: number) -> number
  external static function acos(x: number) -> number
  external static function atan(x: number) -> number
  external static function atan2(y: number, x: number) -> number
  external static function sqrt(x: number) -> number
  external static function exp(x: number) -> number
  external static function log(x: number) -> number

  // Static wrappers of the number instance methods.
  static function abs(x: number)
  static function floor(x: number)
  static function ceil(x: number)
  static function round(x: number)
  static function trunc(x: number)
  static function sign(x: number)

  /// Convert [radians] to degrees, and back.
  external static function degrees(radians)
  external static function radians(degrees)

  // Hetu-specific helpers:
  external static function radiusToSigma(radius: float) -> float

  /// Box–Muller transform for normally distributed random numbers.
  external static function gaussianNoise(mean: float, standardDeviation: float, {min: float, max: float, randomGenerator}) -> float

  /// Noise generation provided by the fast_noise package.
  /// Noise types: perlin, perlinFractal, cubic, cubicFractal
  external static function noise2d(width, height, {seed, noiseType = 'cubic', frequency = 0.01})

  /// Angle from start to end, in degrees / radians.
  external static function angle(startx, starty, endx, endy)
  external static function aangle(startx, starty, endx, endy)

  /// Map input to an output between 0.0 and 1.0 around a target value.
  external static function gradualValue(input, target, { power = 0.5 })
}
```

`min` / `max` accept any number of arguments (variadic): null values are ignored, an empty call returns `Infinity` / `-Infinity`, and NaN propagates.

## Random

The binding of Dart's `Random` object, with some extra helpers such as random colors:

```javascript
external class Random {
  constructor ([seed: integer])

  function nextBool() -> bool

  /// Biased bool: the closer input is to target, the more likely true.
  function nextBoolBiased(input: float, target: float) -> bool

  /// Random integer with a higher / lower probability near the target.
  function nearInt(max: integer, {bias: float = 1.0}) -> integer
  function distantInt(max: integer, {bias: float = 1.0}) -> integer

  function nextInt(max: integer) -> integer
  function nextDouble() -> float

  function nextColorHex({hasAlpha: bool = false}) -> string
  function nextBrightColorHex({hasAlpha: bool = false}) -> string

  function nextIterable(list: Iterable) -> any
  function shuffle(list: Iterable) -> Iterable
}
```

## JSON

```javascript
external abstract class JSON {
  /// Parse a JSON string into Dart data (Map / List / primitives).
  static function parse(object)

  /// Convert a value (including structs) into JSON-ready data.
  static function jsonify(object)

  /// Serialize a value into a JSON string.
  static function stringify(object)

  /// Deep copy a value.
  static function deepcopy(object)
}
```

`stringify` does not support JavaScript's `replacer` / `space` parameters. `jsonify` and `deepcopy` are Hetu extensions.

## console

```javascript
external abstract class console {
  static function log(... args: any)
  static function debug(... args: any)
  static function info(... args: any)
  static function warn(... args: any)
  static function warning(... args: any) // alias of warn
  static function error(... args: any)

  static function time([label: string])
  static function timeLog([label: string])
  static function timeEnd([label: string])
}
```

`time` starts a stopwatch with an optional label, `timeLog` prints the elapsed milliseconds, and `timeEnd` prints and stops it.

## Future / Promise

`Promise` is a type alias of `Future`. JavaScript-style names are provided alongside the Dart names:

```javascript
external class Future {
  constructor (func: function)

  static function wait(futures: List) -> Future
  static function all(futures: List) -> Future      // alias of wait
  static function value(possibleFuture) -> Future
  static function resolve(possibleFuture) -> Future // alias of value
  static function error(error) -> Future
  static function reject(error) -> Future           // alias of error
  static function delayed(seconds: float, [computation: function]) -> Future

  function then(func: (value) -> any) -> Future
  function catchError(func: (error) -> any) -> Future
  function catch(func: (error) -> any) -> Future    // alias of catchError
  function whenComplete(func: () -> any) -> Future
  function finally(func: () -> any) -> Future       // alias of whenComplete
}
```

## crypto

Utility methods for ids and checksums:

```javascript
external abstract class crypto {
  /// A random UUID string.
  static function randomUUID() -> string

  /// A random id with optional time component.
  static function randomUID({length = 4, withTime = false}) -> string

  /// A random numeric id with optional time component.
  static function randomNID({length = 8, withTime = false}) -> string

  static function crcString(data: string, [crc: string = 0]) -> string
  static function crcInt(data: string, [crc: string = 0]) -> integer
}
```
