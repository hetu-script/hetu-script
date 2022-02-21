# Variable

Variable is declared with 'var', 'final', 'late', 'const'. The type annotation and initialize expression is optional.

```dart
var person
var fineStructureConstant: num = 1 / 137
final isTimeTravelSuccessful: bool = true
final skill: List = ['attack', 'defense']
```

## Const

You can declare a constant literal int/float/string value by keyword 'const'. The value will be stored in a global set to slightly increase performance.

```dart
const pi = 3.1415926
```

Constant expression is not computed by default, even the identifier is also a constant. So if the const declaration's initializer is a expression, then it is equal to final declaration.

However, you can turn on constant interpreter by config after version 0.4.0 of Hetu.

```dart
// Equal to final pi2 = 3.1415926 * 2
// at default configuration
const pi2 = 3.1415926 * 2
```

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

You can **omit** a declaration when you use destructuring declaration on a iterable.

```javascript
var [_, _, z] = [1, 2, 3]; // z = 3
```

Destructuring declarations have to have a initializer and have to be initialized immediately, hence you can only use them within a script or a function body.
