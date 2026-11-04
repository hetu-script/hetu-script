# JavaScript 兼容 API 候选清单

本文逐项列举可为 Hetu 增加的 JavaScript 风格 API 名字，是 `plan_js_api_compatibility.md` 的配套清单。列举依据为 JavaScript 标准内建对象（含 ES2023+ 方法），并已逐项对照 Hetu 现有实现（`lib/*.ht` 声明、`packages/hetu_script/lib/binding/class_binding.dart` 绑定、`preinclude/hetu.dart` 注册）。

总原则不变：**Dart 语义为唯一事实来源，只加别名、不加新功能、不改现有行为**。凡 Dart 没有对应能力的，一律列入"不做"。

状态定义：

- **已存在**：Hetu 已有同名 API（可能语义有差异，见说明列）。
- **别名**：现有实现的另一个名字，机械映射，零语义风险。
- **补充暴露**：Dart SDK 已有该能力但尚未绑定到脚本，需要新增少量绑定代码；仍不引入新功能。
- **不做**：Dart 无直接对应、语义冲突过大，或属于 JS 特有怪癖。

优先级：P0 纯别名可立即做；P1 需要少量新绑定，按需做；P2 暂缓，另立讨论。

## 一、顶层对象与全局函数

Hetu 现状：`print/eval/require/help/range/parseInt/parseFloat` 为全局函数；`global` 与 `this` 指向全局命名空间（`hetu.dart:438`）；顶层对象有 `console/JSON/Math/Object/crypto/Random/Future/Promise`。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `globalThis` | 别名 P0 | `global` | 全局命名空间已存在，仅注册别名 |
| `NaN` | 别名 P0 | `float.nan` | 全局常量别名 |
| `Infinity` | 别名 P0 | `float.infinity` | 全局常量别名 |
| `isNaN(x)` | 别名 P0 | `x.isNaN` | `.ht` 包装；JS 全局 `isNaN` 会先隐式转数字，Hetu 不做转换，要求 `number` |
| `isFinite(x)` | 别名 P0 | `x.isFinite` | 同上 |
| `parseInt / parseFloat` | 已存在 | 同名 | 不模拟 JS 的前导零、容错截断等怪癖 |
| `undefined` | 不做 | 用 `null` | 不引入第二套空值语义 |
| `structuredClone(x)` | 别名 P2 | `JSON.deepcopy(x)` | 深拷贝已有；名字较长，收益低，暂缓 |
| `setTimeout / setInterval` | 不做 | 另立计划 | 涉及事件循环语义，不属于命名别名工作 |
| `alert / confirm / prompt` | 不做 | — | 浏览器宿主 API，与语言无关 |

## 二、Object（对应 struct 原型对象）

Hetu 现状：`Object.keys/values/assign/merge/create/fromJSON/hasOwnProperty/contains/containsKey/length/remove/clone/toJSON/toString`。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `Object.keys / values` | 已存在 | 同名 | 一致 |
| `Object.assign` | 已存在 | 同名 | 一致（struct 对 struct） |
| `Object.hasOwn(obj, key)` | 别名 P0 | `hasOwnProperty(key)` | `.ht` 一行包装 |
| `obj.hasOwnProperty(key)` | 已存在 | `containsKey` 的包装 | 一致 |
| `Object.entries(obj)` | 别名（已完成） | `keys.map((k) => MapEntry(k, obj[k])).toList()` | 返回 `List<MapEntry>` |
| `Object.fromEntries(entries)` | 别名（已完成） | `.ht` 组合实现 | 支持 `MapEntry` 与 JS 风格的二元列表对 |
| `Object.create(data)` | 已存在（偏差） | 深拷贝/转换 | **非 JS 原型创建语义**，文档标注，不改行为 |
| `Object.freeze / seal` | 不做 | — | Dart 无对应（`Map.unmodifiable` 是构造新对象） |
| `Object.getPrototypeOf / setPrototypeOf` | 不做 | struct 自有原型机制 | 不套 JS 名字 |
| `Object.is` | 不做 | 用 `==` / `identical` | 语义细微差别（NaN、-0）不值得引入 |

## 三、Array（对应 List / Iterable）

Hetu 现状：实例方法 `map/where/expand/reduce/fold/every/any/join/contains/toList/toSet/take/skip/first/last/firstWhere/lastWhere/elementAt`（Iterable），`add/addAll/insert/remove/removeAt/removeFirst/removeLast/sublist/sort/shuffle/indexOf/lastIndexOf/indexWhere/lastIndexWhere/clear/clone/reversed`（List）。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `push(value)` | 别名 P0 | `add(value)` | 返回 `void`，不返回新长度 |
| `pop()` | 别名 P0 | `removeLast()` | 返回被删元素，一致 |
| `shift()` | 别名 P0 | `removeFirst()` | 返回被删元素，一致 |
| `unshift(value)` | 别名 P0 | `insert(0, value)` | 返回 `void` |
| `filter(test)` | 别名 P0 | `where(test)` | 返回**惰性 Iterable**，需数组时接 `.toList()` |
| `some(test)` | 别名 P0 | `any(test)` | 一致 |
| `includes(value)` | 别名 P0 | `contains(value)` | 一致 |
| `find(test)` | 别名 P0 | `firstWhere(test)` | 无匹配返回 `null`（绑定已提供 `orElse`），接近 JS `undefined` |
| `findIndex(test)` | 别名 P0 | `indexWhere(test)` | 无匹配返回 `-1`，一致 |
| `findLast(test)` | 别名 P0 | `lastWhere(test)` | 同 `find` |
| `findLastIndex(test)` | 别名 P0 | `lastIndexWhere(test)` | 一致 |
| `flatMap(fn)` | 别名 P0 | `expand(fn)` | 返回惰性 Iterable，同 `filter` |
| `slice(start, [end])` | 别名 P0 | `sublist(start, [end])` | 不支持负索引 |
| `forEach(fn)` | 补充暴露（已完成） | Dart `Iterable.forEach` | 回调仅接收元素，不提供 JS 的 `(element, index, array)` 三参形式 |
| `map / reduce / every / join / indexOf / lastIndexOf / sort` | 已存在 | 同名 | `sort` 均为原地排序；默认排序规则 Dart 为自然序、JS 为字典序，文档标注；比较函数用法一致 |
| `at(index)` | 不做 | `elementAt` / `list[i]` | JS `at` 的核心价值是负索引，不引入 |
| `concat` | 不做 | 用 spread：`[...a, ...b]` | 习惯用法替代即可 |
| `splice` | 不做 | `removeRange/insert` 组合 | 参数与返回值语义复杂，别名误导大于收益 |
| `reverse()` | 不做 | `reversed` getter | JS 原地反转 vs Dart 惰性视图，同名会严重误导 |
| `fill / copyWithin` | 不做 | `fillRange/setRange` 组合 | 无单一直接对应 |
| `toSorted / toReversed / toSpliced / with`（ES2023） | 不做 | — | Dart 无对应的非变异方法 |
| `Array.isArray(x)` | 不做 | `x is List` | 类型判断已够用 |
| `Array.from / of` | 不做 | `List(...)` / 字面量 | `type Array = List` 别名已提供（构造与类型注解可用），静态工厂方法不再另加 |

## 四、String

Hetu 现状：`length/substring/trim/trimLeft/trimRight/padLeft/padRight/contains/replaceFirst/replaceAll/replaceRange/split/toLowerCase/toUpperCase/startsWith/endsWith/indexOf/lastIndexOf/codeUnitAt/compareTo/characters`。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `padStart(width, [padding])` | 别名 P0 | `padLeft` | 一致 |
| `padEnd(width, [padding])` | 别名 P0 | `padRight` | 一致 |
| `trimStart() / trimEnd()` | 别名 P0 | `trimLeft / trimRight` | 一致 |
| `charCodeAt(index)` | 别名 P0 | `codeUnitAt(index)` | 均为 UTF-16 码元，一致 |
| `includes(str, [pos])` | 别名 P0 | `contains(str, [startIndex])` | 一致 |
| `replace(from, to)` | 别名 P0 | `replaceFirst(from, to)` | 仅字符串 pattern 场景一致；不支持 JS 正则与 `$` 替换模式 |
| `toExponential / toPrecision` 见 Number 节 | — | — | — |
| `charAt(index)` | 补充暴露（已完成） | Dart `String.operator[]` | 返回单字符字符串 |
| `repeat(n)` | 补充暴露（已完成） | Dart `String.operator*` | 方法形式包装已有运算符能力 |
| `String.fromCharCode(n)` | 补充暴露（已完成） | Dart `String.fromCharCode` | 主名 `String`，小写 `string/str` 为别名 |
| `at / slice / substr` | 不做 | `substring` | 负索引差异，`substr` 在 JS 已废弃 |
| `match / matchAll / search / replaceAll(正则)` | 不做 | 随 RegExp 评估 | 依赖正则能力，见第十二节 |
| `localeCompare` | 不做 | `compareTo` | Dart 为码元序，用 JS 名字会暗示 locale 感知，误导 |
| `normalize` | 不做 | — | Dart 核心库无对应 |
| `codePointAt` | 不做 | `characters` / runes | 无直接对应 |

## 五、Number（number / integer / float）

Hetu 现状：实例 `abs/round/floor/ceil/truncate/sign/clamp/compareTo/remainder/toInt/toDouble/toStringAsFixed/toStringAsExponential/toStringAsPrecision/isNaN/isFinite/isNegative/isInfinite`；`integer` 另有 `modPow/gcd/isEven/bitLength/toRadixString` 等；`float.nan/infinity/maxFinite/minPositive` 静态常量。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `toExponential([digits])` | 别名 P0 | `toStringAsExponential` | 返回 string，与 JS 一致 |
| `toPrecision(digits)` | 别名 P0 | `toStringAsPrecision` | 返回 string，与 JS 一致 |
| `toFixed(digits)` | 已存在（偏差） | `double.parse(toStringAsFixed(...))` | **Hetu 返回 `float`，JS 返回 string**；文档标注，需要字符串时用 `toStringAsFixed` |
| `Number.isNaN(x) / isFinite(x)` | 别名（已完成） | `x.isNaN / x.isFinite` | `Number` 为主名并带静态绑定，`number` 为小写别名；与全局 `isNaN/isFinite` 一致，不做隐式转换 |
| `Number.MAX_VALUE / MIN_VALUE` | 别名 P1 | `float.maxFinite / float.minPositive` | 值一致，但属 JS 历史命名，收益低 |
| `Number.isInteger(x)` | 不做 | `x is integer` | 类型判断替代 |
| `Number.EPSILON` | 不做 | — | Dart 无对应常量 |
| `MAX_SAFE_INTEGER / MIN_SAFE_INTEGER` | 不做 | — | JS 双精度安全整数概念，与 Dart 64 位 int 语义不同 |

## 六、Math

Hetu 现状：静态 `random/min/max/pow/sin/cos/tan/asin/acos/atan/sqrt/exp/log/degrees/radians` 加噪声等扩展；常量 `e/pi/ln2/ln10/log2e/log10e/sqrt2/sqrt1_2`（小写）。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `Math.PI / E / LN2 / LN10 / LOG2E / LOG10E / SQRT2 / SQRT1_2` | 别名 P0 | 同名小写常量 | `static const` 别名 |
| `Math.abs(x)` | 别名 P0 | `x.abs()` | `.ht` 静态包装 |
| `Math.floor / ceil / round` | 别名 P0 | `x.floor() / ceil() / round()` | 同上 |
| `Math.trunc(x)` | 别名 P0 | `x.truncate()` | 同上 |
| `Math.sign(x)` | 别名 P0 | `x.sign` | 同上 |
| `Math.atan2(y, x)` | 补充暴露（已完成） | Dart `dart:math` `atan2` | 一致 |
| `Math.log2 / log10 / cbrt / hypot` | 不做 | — | Dart 无直接函数，不新增数学功能 |
| `Math.min / max` | 已扩展 | variadic | 已扩展为 `... values: number`：多值循环折叠比较，null 忽略，空参数返回 `Infinity`/`-Infinity`，NaN 传播；与 JS 任意多参用法一致 |

## 七、JSON

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `JSON.parse / stringify` | 已存在 | 同名 | 不支持 JS 的 `replacer/reviver/space` 参数，文档标注 |
| `JSON.jsonify / deepcopy` | Hetu 扩展 | — | 保留，兼容矩阵中注明 JS 无此 API |

## 八、Map 与 Set（JS Map/Set 习惯用法）

Hetu 现状：Map 有 `keys/values/length/containsKey/containsValue/addAll/remove/clear` 与下标读写；Set 继承 Iterable 并有 `add/remove/union/intersection/difference` 等。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `map.has(key)` | 别名 P0 | `containsKey(key)` | 一致 |
| `set.has(value)` | 别名 P0 | `contains(value)`（继承自 Iterable） | 一致 |
| `set.delete(value)` | 别名（已完成） | `Set.remove(value)` | 均返回 bool；`delete` 已改为上下文关键字（移出保留字集合），成员名可用 |
| `map.size / set.size` | 别名 P0 | `length` getter | 一致 |
| `map.get(key) / map.set(key, value)` | 补充暴露（已完成） | Dart `operator[] / []=` | `set` 返回 void，不返回 map 本身 |
| `map.delete(key)` | 补充暴露（已完成） | `remove(key)` | 返回被删值而非 JS 的 bool；`delete` 已改为上下文关键字，成员名可用 |
| `map.entries()` | 补充暴露（已完成） | Dart `Map.entries` | 返回 `Iterable<MapEntry>`；同时补注册了漏掉的 `HTMapEntryBinding` |
| `map.forEach(fn)` | 补充暴露（已完成） | Dart `Map.forEach` | 回调为 `(key, value)`，与 JS 参数顺序 `(value, key)` 不同，文档标注 |
| `set.union / intersection / difference` | 已存在 | 同名 | 与 ES2024 JS Set 方法同名，一致 |
| `set.symmetricDifference / isSubsetOf` 等 | 不做 | — | Dart 无对应 |

## 九、Promise（Future）

Hetu 现状：`type Promise = Future`；`then`；静态 `Future.wait/value/delayed`。

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `Promise.resolve(x)` | 别名（已完成） | `Future.value(x)` | 类型别名静态成员访问已修复，通过 `type Promise = Future` 直接可用 |
| `Promise.all(list)` | 别名（已完成） | `Future.wait(list)` | 同上 |
| `promise.catch(fn)` | 补充暴露（已完成） | Dart `Future.catchError` | 已验证 `catch/finally` 可作成员名；同时提供 `catchError/whenComplete` 原名 |
| `promise.finally(fn)` | 补充暴露（已完成） | Dart `Future.whenComplete` | 同上 |
| `Promise.reject(x)` | 补充暴露（已完成） | Dart `Future.error` | 同时提供 `Future.error` 原名 |
| `Promise.race / allSettled / any / withResolvers` | 不做 | — | Dart 无直接对应 |

## 十、console

| JS API | 状态 | Hetu 对应 | 说明 |
| --- | --- | --- | --- |
| `console.warn(...)` | 已决定（主名） | 脚本侧统一以 `warn` 为主名，`warning` 保留为别名 | 与 JS 及 SLF4J/Ruby/Rust/Go/spdlog 等主流 logger 的方法名一致；Dart 内部 `MessageSeverity.warning` 与级别名 `WARNING` 不动（级别名用 WARNING 是各语言通例） |
| `console.warning(...)` | 保留别名 | 转发 `warn` 同一实现 | 不再作为主名文档推荐，仅为兼容存量脚本保留 |
| `log / debug / info / error / time / timeLog / timeEnd` | 已存在 | 同名 | 一致 |
| `console.table / dir / trace / group / assert` | 不做 | — | Dart 无对应，属新功能 |

## 十一、crypto

Hetu 的 `crypto.randomUUID()` 与 JS `crypto.randomUUID()` 已同名同用途（巧合的一致），其余 `randomUID/randomNID/crcString/crcInt` 为 Hetu 扩展。JS 的 `crypto.getRandomValues/subtle` 不做（Dart 无直接对应，属密码学新功能）。

## 十二、不建议以 JS 名字兼容的对象

| JS 对象 | 建议 | 原因 |
| --- | --- | --- |
| `Date` | 不做 JS 别名；如需日期功能，另立计划暴露 Dart `DateTime` 原名 API | 月份 0 基 vs 1 基等差异是经典陷阱，别名必然误导 |
| `RegExp` | 可选：暴露 Dart `RegExp` 原名（`hasMatch/firstMatch` 等），不做 `exec/test` 别名 | JS 正则有 `lastIndex` 状态等语义，Dart 无对应 |
| `Error / TypeError / RangeError` | 不做 | Hetu 允许 `throw` 任意值，错误体系不同 |
| `Symbol / Proxy / Reflect / WeakRef` | 不做 | Dart 无对应或超出语言定位 |
| `ArrayBuffer / DataView / TypedArray` | 不做 | 需要时可按 Dart `ByteData/Uint8List` 原名另立绑定计划 |
| `Function.prototype.call/apply/bind` | 不做 | Hetu 函数调用约定不同（命名参数等），套 JS 名字会误导 |

## 汇总

- **P0（纯别名，已完成）**：顶层 `globalThis/NaN/Infinity/isNaN/isFinite`；List 的 `push/pop/shift/unshift/filter/some/includes/find/findIndex/findLast/findLastIndex/flatMap/slice`；String 的 `padStart/padEnd/trimStart/trimEnd/charCodeAt/includes/replace`；Number 的 `toExponential/toPrecision/Number.isNaN/isFinite`；Math 的常量与 `abs/floor/ceil/round/trunc/sign`，以及 `min/max` 的 variadic 扩展；`Object.hasOwn`；Map/Set 的 `has/size`；`Promise.resolve/all`；`console.warn`（主名，`warning` 保留别名）。实现见 `plan_js_api_compatibility.md` 执行记录。
- **P1（少量新绑定，已完成）**：`forEach`（Iterable/Map）、`Map.get/set/delete/entries`、`Set.delete`、`Promise.catch/finally/reject`、`Math.atan2`、`String.charAt/repeat/fromCharCode`、`Object.entries/fromEntries`；并补注册了漏掉的 `HTMapEntryBinding`。`delete` 已通过移出保留字集合改为上下文关键字，`Map/Set.delete` 均可用。基础类型主名已统一为大写（`Number/Integer/Float/Bool/String`），小写 `number/integer/float/bool/string` 与 `num/int/double/str` 均保留为别名。
- **P2 / 不做**：`structuredClone`、`Number.MAX_VALUE`；Date、RegExp、Timer、正则字符串方法、负索引相关、JS 语义怪癖等，理由见各表。

执行时按 `plan_js_api_compatibility.md` 的阶段划分推进；每完成一项，在兼容矩阵文档中登记其状态与语义说明。
