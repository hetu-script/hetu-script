# JavaScript Developers

If you come from JavaScript or TypeScript, you can use many of the standard library APIs with the names you already know: `push`, `filter`, `includes`, `padStart`, `Math.PI`, `Promise.resolve`, `console.warn`, and so on.

**One principle to keep in mind:** these names are aliases of the Dart-backed implementations, not reimplementations of JavaScript. The behavior (return values, exceptions, laziness, parameter rules) always follows the Dart SDK. This keeps script values fully interoperable with the Dart host — a `List` passed between Dart and Hetu needs no wrapping or conversion in either direction.

```typescript
var list = [1, 2, 3]
list.push(4)
var evens = list.filter((n) => n % 2 == 0).toList()
console.warn('evens:', evens) // evens: [2, 4]

var text = '7'.padStart(3, '0') // '007'
var max = Math.max(3, 1, 4, 1, 5) // 5, variadic like JavaScript

Promise.resolve(42).then((value) => print(value))
```

## Global scope

| JavaScript name | Notes |
| --- | --- |
| `globalThis` | Alias of `global`, the global namespace. |
| `NaN`, `Infinity` | Aliases of `float.nan` / `float.infinity`. |
| `isNaN(x)`, `isFinite(x)` | No implicit conversion; the input must be a `number`. |
| `parseInt(source, [radix])`, `parseFloat(source)` | No JavaScript quirks (no leading-zero or partial-parse leniency beyond Dart's `tryParse`). |

There is no `undefined` and no `arguments` object. Use `null`, and use variadic parameters (`function f(... args)`) which give you a real `List`, instead of JavaScript's `arguments`.

## Array methods (List / Iterable)

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `push(value)` | `add(value)` | Returns `void`, not the new length. |
| `pop()` | `removeLast()` | Returns the removed element. |
| `shift()` | `removeFirst()` | Returns the removed element. |
| `unshift(value)` | `insert(0, value)` | Returns `void`. |
| `filter(test)` | `where(test)` | Returns a **lazy** `Iterable`; call `.toList()` for an array. |
| `some(test)` | `any(test)` | |
| `includes(value)` | `contains(value)` | |
| `find(test)` | `firstWhere(test)` | Returns `null` when nothing matches. |
| `findLast(test)` | `lastWhere(test)` | Returns `null` when nothing matches. |
| `findIndex(test)` | `indexWhere(test)` | Returns `-1` when nothing matches. |
| `findLastIndex(test)` | `lastIndexWhere(test)` | Returns `-1` when nothing matches. |
| `flatMap(fn)` | `expand(fn)` | Lazy, like `filter`. |
| `slice(start, [end])` | `sublist(start, [end])` | No negative indexes. |
| `forEach(fn)` | Dart `Iterable.forEach` | Callback receives the element only, not `(element, index, array)`. |

Already available with the same names: `map`, `reduce`, `every`, `join`, `indexOf`, `lastIndexOf`, `sort` (in-place; the default order is Dart's natural ordering, not JavaScript's string ordering).

Deliberately not provided: `at` (negative indexing), `concat` (use spread: `[...a, ...b]`), `splice`, `reverse` (JavaScript mutates in place, Dart's `reversed` is a lazy view), `toSorted`/`toReversed`/`with`, and `Array.isArray` (use `x is List`).

## String methods

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `padStart(width, [padding])` | `padLeft` | |
| `padEnd(width, [padding])` | `padRight` | |
| `trimStart()` / `trimEnd()` | `trimLeft` / `trimRight` | |
| `charCodeAt(index)` | `codeUnitAt(index)` | Both are UTF-16 code units. |
| `charAt(index)` | `string[index]` operator | |
| `includes(str, [pos])` | `contains(str, [startIndex])` | |
| `replace(from, to)` | `replaceFirst(from, to)` | String patterns only; no regex or `$` substitution patterns. |
| `repeat(n)` | Dart `String operator*` | |
| `String.fromCharCode(n)` | Dart `String.fromCharCode` | `String` is a type alias of `string`. |

Already available with the same names: `substring`, `split`, `trim`, `startsWith`, `endsWith`, `indexOf`, `lastIndexOf`, `toLowerCase`, `toUpperCase`, `replaceAll`.

## Number methods

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `toExponential([digits])` | `toStringAsExponential` | Returns a string. |
| `toPrecision(digits)` | `toStringAsPrecision` | Returns a string. |
| `Number.isNaN(x)` / `Number.isFinite(x)` | `x.isNaN` / `x.isFinite` | Static forms via `type Number = number`. |

**`toFixed` differs:** Hetu's `float.toFixed(digits)` returns a `float` (rounded value), while JavaScript returns a string. Use `toStringAsFixed(digits)` when you need the string form.

## Math

Constants are available in both casings: `Math.PI`, `Math.E`, `Math.LN2`, `Math.LN10`, `Math.LOG2E`, `Math.LOG10E`, `Math.SQRT2`, `Math.SQRT1_2`.

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `abs(x)`, `floor(x)`, `ceil(x)`, `round(x)`, `sign(x)` | Instance methods | Static wrappers. |
| `trunc(x)` | `x.truncate()` | |
| `atan2(y, x)` | Dart `dart:math` `atan2` | |
| `min(...values)`, `max(...values)` | Variadic | Null values are ignored; with no arguments returns `Infinity` / `-Infinity`; NaN propagates. |

Already available with the same names: `random`, `pow`, `sqrt`, `exp`, `log`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`.

## Object (struct)

Hetu's object literals (`{a: 1}`) are prototype-based structs, not JavaScript objects.

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `Object.hasOwn(obj, key)` | `obj.containsKey(key)` | |
| `obj.hasOwnProperty(key)` | `containsKey` | |
| `Object.entries(obj)` | — | Returns a `List` of `MapEntry` (`.key` / `.value`). |
| `Object.fromEntries(entries)` | — | Accepts `MapEntry` items or two-element `[key, value]` lists. |
| `Object.keys` / `Object.values` / `Object.assign` | — | Already available. |

**`Object.create` differs:** in Hetu it deep-copies or converts its argument into a struct; it does **not** create an object with a given prototype like JavaScript.

## Map and Set

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `map.has(key)` / `set.has(value)` | `containsKey` / `contains` | |
| `map.size` / `set.size` | `length` | |
| `map.get(key)` / `map.set(key, value)` | `[]` / `[]=` operators | `set` returns `void`, not the map. |
| `map.delete(key)` | `remove(key)` | Returns the removed value, not a boolean. |
| `set.delete(value)` | `Set.remove(value)` | Returns a boolean, like JavaScript. |
| `map.entries` | Dart `Map.entries` | An `Iterable` of `MapEntry`. |
| `map.forEach(fn)` | Dart `Map.forEach` | Callback is `(key, value)` — **opposite of JavaScript's `(value, key)`**. |
| `set.union` / `intersection` / `difference` | — | Same names as the ES2024 Set methods. |

`delete` is a contextual keyword in Hetu: a statement starting with `delete` is always a delete statement (`delete obj.a`), while `map.delete(key)` is a normal method call.

## Promise (Future)

`Promise` is a type alias of `Future`, and static members work through the alias.

| JavaScript name | Equivalent | Notes |
| --- | --- | --- |
| `Promise.resolve(x)` | `Future.value(x)` | |
| `Promise.all(list)` | `Future.wait(list)` | |
| `Promise.reject(x)` | `Future.error(x)` | |
| `promise.catch(fn)` | `catchError` | Also available under the Dart name. |
| `promise.finally(fn)` | `whenComplete` | Also available under the Dart name. |
| `promise.then(fn)` | `then` | Already available. |

Not provided: `Promise.race`, `allSettled`, `any`, `withResolvers` (no direct Dart counterparts).

## console and JSON

`console.log/debug/info/error/time/timeLog/timeEnd` share their JavaScript names. **`console.warn`** is the primary name for warnings; `console.warning` is kept as an alias.

`JSON.parse` and `JSON.stringify` work as expected, but without the `replacer`/`reviver`/`space` parameters. Hetu also has two extensions that do not exist in JavaScript: `JSON.jsonify` (convert a value into JSON-ready data) and `JSON.deepcopy`.

## What is intentionally not emulated

- JavaScript's coercion rules, `==` loose equality, `this` binding rules, and prototype-chain semantics.
- Negative indexing (`at`, `slice` with negative arguments).
- `Date` (month numbering differs fundamentally; use Dart-style APIs if a date binding is added in the future).
- `RegExp` methods with JavaScript stateful semantics (`exec`/`lastIndex`).
- `setTimeout`/`setInterval` (these are host event-loop APIs, not naming aliases).
