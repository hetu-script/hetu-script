# 河图中提供的 API

河图中的基础类型本身就是 Dart 对象，同时也默认绑定了大多数 Dart SDK 中的方法：**number**、**integer**、**float**、**bool**、**string**、**List**、**Set**、**Map**、**Iterable**、**BigInt**。

例如，我们可以在脚本中对 Iterable 使用 Dart 的 `map` 接口：

```dart
final result = range(10).map((value) => 'row: ${value}')
```

这些 API 中的许多还提供了 **JavaScript 风格的别名**（`push`、`filter`、`padStart`、`Math.PI`、`Promise.resolve` 等）。完整的别名对照表和需要注意的语义差异，请参阅 [JavaScript 开发者指南](/zh-Hans/guide/javascript/)。

为方便使用提供的类型别名：`num`（= `number`）、`int`（= `integer`）、`double`（= `float`）、`str` / `String`（= `string`）、`Number`（= `number`）、`Promise`（= `Future`）。

## 全局函数和值

```javascript
external function print(... args: any)
external function range(startOrStop: number, [stop: number, step: number]) -> Iterable
external function eval(code: string)
external function require(path: string)
external function help(id: string)
external function parseInt(source: string, [radix: integer?]) -> number
external function parseFloat(source: string) -> number
```

- `print`：把一个或多个对象字符串化并打印到标准输出。
- `range`：生成数字序列，可指定步长。
- `eval`：动态执行一段河图源代码字符串。
- `require`：在当前 source context 上动态导入一个源文件，返回其命名空间。
- `help`：打印某个标识符的文档，例如 `help(require)`。
- `parseInt` / `parseFloat`：从字符串解析数字（Dart `tryParse` 语义）。

全局作用域中还提供：

- `global` / `globalThis`：全局命名空间对象。
- `NaN`、`Infinity`：`float.nan` 和 `float.infinity` 的别名。
- `isNaN(x)`、`isFinite(x)`：对应实例 getter 的包装，不做隐式转换。
- `kHetuVersion`：语言版本号字符串。

### eval()

和 JavaScript 一样，脚本中包含一个用以解释自身的接口 **eval()**：

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

## 结构体 Object

河图包含类似 JavaScript 的对象字面量语法，并实现了原型链。所有结构体共享根原型 `Object`，其上预定义了以下成员：

```typescript
struct Object {
  /// 从 Dart 的 JSON Map 创建结构体。
  external static function fromJSON(data) -> {}

  /// 把源对象的成员赋值到目标对象。
  external static function assign(target, source)

  /// 仅当目标不存在该键时才赋值。
  external static function merge(target, source)

  /// 检查是否包含某键（包括原型链）。
  external function contains(key: string) -> bool

  /// 仅检查自身字段是否包含某键。
  external function containsKey(key: string) -> bool

  external get keys -> Iterable
  external get values -> Iterable
  external get isEmpty -> bool
  external get isNotEmpty -> bool
  external get length -> integer

  /// 按键删除字段。
  external function remove(key: string) -> any

  /// 深拷贝此结构体。
  external function clone() -> {}

  function hasOwnProperty(key: string) => this.containsKey(key)
  static function hasOwn(object, key: string) => object.containsKey(key)

  /// 自身字段的 MapEntry 列表。
  static function entries(object)

  /// 从 MapEntry 或 [key, value] 二元列表创建结构体。
  static function fromEntries(entries)

  function toJSON() -> Map => JSON.jsonify(this)
  function toString() -> string => JSON.stringify(this)

  /// 对参数深拷贝/转换得到结构体。
  ///（与 JavaScript 按原型创建的 Object.create 不同。）
  function create(data)
}
```

实例成员可以直接在任意结构体上调用：

```javascript
final obj = { a: 42 }
obj.contains('a') // true
```

静态方法需要通过原型的名字调用：

```dart
final book = Object.fromJSON(data);
```

## Math

`Math` 静态类整合了 Dart 的 `dart:math` 库、JavaScript 风格别名，以及一些河图特有的辅助函数。

常量：`e`、`pi`、`ln2`、`ln10`、`log2e`、`log10e`、`sqrt2`、`sqrt1_2`，以及大写别名 `E`、`PI`、`LN2`、`LN10`、`LOG2E`、`LOG10E`、`SQRT2`、`SQRT1_2`。

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

  // number 实例方法的静态包装。
  static function abs(x: number)
  static function floor(x: number)
  static function ceil(x: number)
  static function round(x: number)
  static function trunc(x: number)
  static function sign(x: number)

  /// 弧度与角度互相转换。
  external static function degrees(radians)
  external static function radians(degrees)

  // 河图特有的辅助函数：
  external static function radiusToSigma(radius: float) -> float

  /// Box–Muller 变换，生成正态分布随机数。
  external static function gaussianNoise(mean: float, standardDeviation: float, {min: float, max: float, randomGenerator}) -> float

  /// fast_noise 包提供的噪声生成。
  /// 噪声类型：perlin、perlinFractal、cubic、cubicFractal
  external static function noise2d(width, height, {seed, noiseType = 'cubic', frequency = 0.01})

  /// 起点到终点的角度（角度制 / 弧度制）。
  external static function angle(startx, starty, endx, endy)
  external static function aangle(startx, starty, endx, endy)

  /// 根据输入与目标的距离，映射出 0.0 到 1.0 之间的值。
  external static function gradualValue(input, target, { power = 0.5 })
}
```

`min` / `max` 支持任意多个参数（可变参数）：忽略 null 值；无参数调用返回 `Infinity` / `-Infinity`；NaN 正常传播。

## Random

Dart `Random` 对象的绑定，附带一些额外的辅助接口，例如生成随机颜色：

```javascript
external class Random {
  constructor ([seed: integer])

  function nextBool() -> bool

  /// 带偏置的布尔值：input 越接近 target，越可能为 true。
  function nextBoolBiased(input: float, target: float) -> bool

  /// 生成的整数更可能 / 更不可能接近目标值。
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
  /// 把 JSON 字符串解析为 Dart 数据（Map / List / 基本类型）。
  static function parse(object)

  /// 把值（包括结构体）转换为可 JSON 序列化的数据。
  static function jsonify(object)

  /// 把值序列化为 JSON 字符串。
  static function stringify(object)

  /// 深拷贝一个值。
  static function deepcopy(object)
}
```

`stringify` 不支持 JavaScript 的 `replacer` / `space` 参数。`jsonify` 和 `deepcopy` 是河图的扩展接口。

## console

```javascript
external abstract class console {
  static function log(... args: any)
  static function debug(... args: any)
  static function info(... args: any)
  static function warn(... args: any)
  static function warning(... args: any) // warn 的别名
  static function error(... args: any)

  static function time([label: string])
  static function timeLog([label: string])
  static function timeEnd([label: string])
}
```

`time` 用可选标签启动一个秒表；`timeLog` 打印已经过的毫秒数；`timeEnd` 打印并停止秒表。

## Future / Promise

`Promise` 是 `Future` 的类型别名。JavaScript 风格名字与 Dart 原名同时提供：

```javascript
external class Future {
  constructor (func: function)

  static function wait(futures: List) -> Future
  static function all(futures: List) -> Future      // wait 的别名
  static function value(possibleFuture) -> Future
  static function resolve(possibleFuture) -> Future // value 的别名
  static function error(error) -> Future
  static function reject(error) -> Future           // error 的别名
  static function delayed(seconds: float, [computation: function]) -> Future

  function then(func: (value) -> any) -> Future
  function catchError(func: (error) -> any) -> Future
  function catch(func: (error) -> any) -> Future    // catchError 的别名
  function whenComplete(func: () -> any) -> Future
  function finally(func: () -> any) -> Future       // whenComplete 的别名
}
```

## crypto

提供 id 生成和校验和相关的工具方法：

```javascript
external abstract class crypto {
  /// 随机 UUID 字符串。
  static function randomUUID() -> string

  /// 随机 id，可附加时间分量。
  static function randomUID({length = 4, withTime = false}) -> string

  /// 随机数字 id，可附加时间分量。
  static function randomNID({length = 8, withTime = false}) -> string

  static function crcString(data: string, [crc: string = 0]) -> string
  static function crcInt(data: string, [crc: string = 0]) -> integer
}
```
