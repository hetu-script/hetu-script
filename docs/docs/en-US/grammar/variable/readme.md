# Variable

Variable is declared with 'var', 'final', 'late', 'const'. The type annotation and initialize expression is optional.

```dart
var person
var fineStructureConstant: number = 1 / 137
final isTimeTravelSuccessful: bool = true
final skill: List = ['attack', 'defense']
```

## Const

You can declare a constant literal value by keyword `const`. Four constant types are supported: boolean, integer, float, and string. Constant values are stored in a global deduplication table to improve performance — identical constant values share the same storage.

```dart
const pi = 3.1415926
const name = 'Hetu'
const isReady = true
const answer = 42
```

Constant expression evaluation is not enabled by default. A `const` declaration whose initializer contains runtime expressions behaves like `final`.

However, you can enable constant expression computation by setting `computeConstantExpression: true` in the Hetu config (available since version 0.4.0):

```dart
// With computeConstantExpression: true, this is computed at compile time:
const pi2 = 3.1415926 * 2

// Without it (default), this behaves like:
// final pi2 = 3.1415926 * 2
```

**Differences between `const` and `final`:**
- `const` values are compile-time constants stored in a deduplicated global table.
- `final` values are runtime-assigned once immutable variables.
- `const` can only hold literal values (by default); `final` can hold any runtime value.

## Late finalize

For var & final declaration, you will get a null value before you initialize it.

You can declare a **immutable** variable while not initialize it immediately, by using keyword **late**.

It will become immutable after the first assignment. And you will get a runtime error if you try to get its value.

```dart
late a
// print(a) // Error: [a] is not initialized yet.
a = 42
print(a)
a = 'dragon' // Error: [a] is immutable.
```

## Shadowing

It is possible to shadow a variable by defining another variable with the same name.

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## Delete

It is possible to delete a variable using 'delete' keyword.

```dart
var a = 42
delete a
print(a) // error: a is undefined!
```

## Destructuring declaration

You **cannot** define multiple variables at the same time like you would in C++ and Java. This is for the sake of clarity.

```dart
var a,b,c// error
```

However, you can use **destructuring declaration** to assign multiple values from an Iterable/struct/map.

```javascript
var [a, b, c] = [1, 2, 3]; // a = 1, b = 2, c = 3
var { x, y } = { x: 6, y: 7 }; // x = 6, y = 7
```

### Omitting values with `_`

When destructuring from a list/iterable, use `_` to skip values you don't need:

```javascript
var [_, _, z] = [1, 2, 3]; // z = 3
```

### Destructuring from structs

When destructuring from a struct, the variable names must match the field names:

```javascript
final obj = { a: 6, b: 7 }
final { a, b } = obj  // a = 6, b = 7
```

### Requirements

Destructuring declarations **must** have an initializer and must be initialized immediately. They can be used within a script body (`ResourceType.hetuScript`) or a function body, but not in class-level declarations.
