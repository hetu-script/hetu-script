# Variable

Variable is declared with 'var', 'final', 'late', 'const'. The type annotation and initialize expression is optional.

```dart
var person
var fineStructureConstant: num = 1 / 137
final isTimeTravelSuccessful: bool = true
final skill: List = ['attack', 'defense']
```

## String interpolation

String literal can have interpolation the same to Javascript, you can use any expression within '${}':

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

Note it's different to Dart that you have to write a curly brackets even if you have only one identifier.

## Late finalize

You can declare a **immutable** variable while not initialize it immediately, by using keyword **late**.

It will become immutable after the first assignment.

```dart
late a
// print(a) // Error: [a] is not initialized yet.
a = 42
print(a)
a = 'dragon' // Error: [a] is immutable.
```

## Const

You can declare a const literal int/float/string value by keyword 'const'.

```dart
const pi = 3.1415926
```

**You cannot declare a const expressions or functions for now. They are still WIP.**

```dart
const pi2 = 3.1415926 * 2 // error!
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

## Destructuring declaration (destructural assign, structured binding)

Destructuring declaration is a syntax for assigning multiple values from an array or a map.

```javascript
var [a, b, c] = [1, 2, 3]; // a = 1, b = 2, c = 3
var { x, y } = { x: 6, y: 7 }; // x = 6, y = 7
```

Destructuring declarations have to have a initializer and have to be initialized immediately, hence you can only use them within a script or a function body.

**You cannot use them within Class, Named struct and Namespace's definition.**

## Multiple declaration

You **cannot** define multiple variables at the same time like you would in C++ and Java. This is for the sake of clarity.

```dart
var a,b,c// error
```
