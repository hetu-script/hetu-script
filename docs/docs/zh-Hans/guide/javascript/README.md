# JavaScript 开发者指南

如果你熟悉 JavaScript 或 TypeScript，河图的许多标准库 API 可以直接用你已经习惯的名字来调用：`push`、`filter`、`includes`、`padStart`、`Math.PI`、`Promise.resolve`、`console.warn` 等等。

**需要记住的一条原则：** 这些名字是 Dart 实现的别名，而不是对 JavaScript 的重新实现。行为（返回值、异常、惰性求值、参数规则）一律以 Dart SDK 为准。这样可以保证脚本值与 Dart 宿主之间的完全互操作——`List` 在 Dart 和河图之间传递时不需要任何包装或转换。

```typescript
var list = [1, 2, 3]
list.push(4)
var evens = list.filter((n) => n % 2 == 0).toList()
console.warn('evens:', evens) // evens: [2, 4]

var text = '7'.padStart(3, '0') // '007'
var max = Math.max(3, 1, 4, 1, 5) // 5，与 JavaScript 一样支持多参数

Promise.resolve(42).then((value) => print(value))
```

## 全局作用域

| JavaScript 名字 | 说明 |
| --- | --- |
| `globalThis` | `global`（全局命名空间）的别名。 |
| `NaN`、`Infinity` | `float.nan` / `float.infinity` 的别名。 |
| `isNaN(x)`、`isFinite(x)` | 不做隐式转换，输入必须是 `number`。 |
| `parseInt(source, [radix])`、`parseFloat(source)` | 不模拟 JS 的解析怪癖（行为以 Dart 的 `tryParse` 为准）。 |

河图没有 `undefined`，也没有 `arguments` 对象。空值请使用 `null`；可变参数请使用 variadic 形参（`function f(... args)`），它在函数体内就是一个真正的 `List`，可替代 JS 的 `arguments`。

## 数组方法（List / Iterable）

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `push(value)` | `add(value)` | 返回 `void`，不返回新长度。 |
| `pop()` | `removeLast()` | 返回被移除的元素。 |
| `shift()` | `removeFirst()` | 返回被移除的元素。 |
| `unshift(value)` | `insert(0, value)` | 返回 `void`。 |
| `filter(test)` | `where(test)` | 返回**惰性** `Iterable`，需要数组时调用 `.toList()`。 |
| `some(test)` | `any(test)` | |
| `includes(value)` | `contains(value)` | |
| `find(test)` | `firstWhere(test)` | 无匹配时返回 `null`。 |
| `findLast(test)` | `lastWhere(test)` | 无匹配时返回 `null`。 |
| `findIndex(test)` | `indexWhere(test)` | 无匹配时返回 `-1`。 |
| `findLastIndex(test)` | `lastIndexWhere(test)` | 无匹配时返回 `-1`。 |
| `flatMap(fn)` | `expand(fn)` | 与 `filter` 一样是惰性求值。 |
| `slice(start, [end])` | `sublist(start, [end])` | 不支持负索引。 |
| `forEach(fn)` | Dart `Iterable.forEach` | 回调只接收元素，不是 JS 的 `(element, index, array)`。 |

已同名提供：`map`、`reduce`、`every`、`join`、`indexOf`、`lastIndexOf`、`sort`（原地排序；默认顺序为 Dart 的自然排序，不是 JS 的字符串字典序）。

`Array` 已作为 `List` 的类型别名提供：可以用 `Array()` 构造列表，也可以在类型注解中写 `var l: Array`。

明确不提供：`at`（负索引）、`concat`（请用 spread：`[...a, ...b]`）、`splice`、`reverse`（JS 是原地反转，Dart 的 `reversed` 是惰性视图，同名会误导）、`toSorted`/`toReversed`/`with`、`Array.isArray`（请用 `x is List`）。

## 字符串方法

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `padStart(width, [padding])` | `padLeft` | |
| `padEnd(width, [padding])` | `padRight` | |
| `trimStart()` / `trimEnd()` | `trimLeft` / `trimRight` | |
| `charCodeAt(index)` | `codeUnitAt(index)` | 均为 UTF-16 码元。 |
| `charAt(index)` | `string[index]` 运算符 | |
| `includes(str, [pos])` | `contains(str, [startIndex])` | |
| `replace(from, to)` | `replaceFirst(from, to)` | 仅支持字符串模式，不支持正则和 `$` 替换模式。 |
| `repeat(n)` | Dart `String operator*` | |
| `String.fromCharCode(n)` | Dart `String.fromCharCode` | `String` 为类名，`string` / `str` 为小写别名。 |

已同名提供：`substring`、`split`、`trim`、`startsWith`、`endsWith`、`indexOf`、`lastIndexOf`、`toLowerCase`、`toUpperCase`、`replaceAll`。

## 数字方法

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `toExponential([digits])` | `toStringAsExponential` | 返回字符串。 |
| `toPrecision(digits)` | `toStringAsPrecision` | 返回字符串。 |
| `Number.isNaN(x)` / `Number.isFinite(x)` | `x.isNaN` / `x.isFinite` | `Number` 为类名，`number` 为小写别名。 |

**`toFixed` 有差异：** 河图的 `float.toFixed(digits)` 返回 `float`（舍入后的数值），而 JavaScript 返回字符串。需要字符串形式时请使用 `toStringAsFixed(digits)`。

## Math

常量同时提供大小写两种形式：`Math.PI`、`Math.E`、`Math.LN2`、`Math.LN10`、`Math.LOG2E`、`Math.LOG10E`、`Math.SQRT2`、`Math.SQRT1_2`。

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `abs(x)`、`floor(x)`、`ceil(x)`、`round(x)`、`sign(x)` | 同名实例方法 | 静态包装。 |
| `trunc(x)` | `x.truncate()` | |
| `atan2(y, x)` | Dart `dart:math` 的 `atan2` | |
| `min(...values)`、`max(...values)` | 可变参数 | 忽略 null 值；无参数时返回 `Infinity` / `-Infinity`；NaN 正常传播。 |

已同名提供：`random`、`pow`、`sqrt`、`exp`、`log`、`sin`、`cos`、`tan`、`asin`、`acos`、`atan`。

## Object（结构体）

河图的对象字面量（`{a: 1}`）是基于原型的结构体（struct），不是 JavaScript 对象。

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `Object.hasOwn(obj, key)` | `obj.containsKey(key)` | |
| `obj.hasOwnProperty(key)` | `containsKey` | |
| `Object.entries(obj)` | — | 返回 `MapEntry`（`.key` / `.value`）组成的 `List`。 |
| `Object.fromEntries(entries)` | — | 接受 `MapEntry` 或 `[key, value]` 二元列表。 |
| `Object.keys` / `Object.values` / `Object.assign` | — | 已提供。 |

**`Object.create` 有差异：** 河图中它是对参数进行深拷贝/转换得到结构体，**不是** JavaScript 的按原型创建对象。

## Map 和 Set

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `map.has(key)` / `set.has(value)` | `containsKey` / `contains` | |
| `map.size` / `set.size` | `length` | |
| `map.get(key)` / `map.set(key, value)` | `[]` / `[]=` 运算符 | `set` 返回 `void`，不返回 map 本身。 |
| `map.delete(key)` | `remove(key)` | 返回被删值，不是布尔值。 |
| `set.delete(value)` | `Set.remove(value)` | 返回布尔值，与 JS 一致。 |
| `map.entries` | Dart `Map.entries` | `MapEntry` 组成的 `Iterable`。 |
| `map.forEach(fn)` | Dart `Map.forEach` | 回调为 `(key, value)`——**与 JS 的 `(value, key)` 顺序相反**。 |
| `set.union` / `intersection` / `difference` | — | 与 ES2024 的 Set 方法同名。 |

`delete` 在河图中是上下文关键字：以 `delete` 开头的语句总是 delete 语句（如 `delete obj.a`），而 `map.delete(key)` 是普通的方法调用。

## Promise（Future）

`Promise` 是 `Future` 的类型别名，静态成员可以通过别名直接访问。

| JavaScript 名字 | 对应实现 | 说明 |
| --- | --- | --- |
| `Promise.resolve(x)` | `Future.value(x)` | |
| `Promise.all(list)` | `Future.wait(list)` | |
| `Promise.reject(x)` | `Future.error(x)` | |
| `promise.catch(fn)` | `catchError` | 同时提供 Dart 原名。 |
| `promise.finally(fn)` | `whenComplete` | 同时提供 Dart 原名。 |
| `promise.then(fn)` | `then` | 已提供。 |

不提供：`Promise.race`、`allSettled`、`any`、`withResolvers`（Dart 无直接对应）。

## console 和 JSON

`console.log/debug/info/error/time/timeLog/timeEnd` 与 JavaScript 同名。警告日志的主名是 **`console.warn`**，`console.warning` 保留为别名。

`JSON.parse` 和 `JSON.stringify` 可正常使用，但不支持 `replacer`/`reviver`/`space` 参数。河图另有两个 JS 中不存在的扩展：`JSON.jsonify`（把值转换为可 JSON 序列化的数据）和 `JSON.deepcopy`（深拷贝）。

## 明确不模拟的内容

- JavaScript 的隐式类型转换、`==` 宽松相等、`this` 绑定规则和原型链语义。
- 负索引（`at`、负参数的 `slice`）。
- `Date`（月份计数方式根本不同；如未来提供日期绑定，将使用 Dart 风格 API）。
- 带 JS 状态语义的 `RegExp` 方法（`exec`/`lastIndex`）。
- `setTimeout`/`setInterval`（属于宿主事件循环 API，不是命名别名）。
