# Variable

Variable is declared with 'var', 'final', 'late'. The type annotation and initialize expression is optional.

```dart
var person;
var fineStructureConstant: num = 1 / 137;
final isTimeTravelSuccessful: bool = true;
final skill: List = ['attack', 'defense'];
```

String literal can have interpolation the same to Javascript:

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

A little difference from Dart is that you have to write a curly brackets even if you have only one identifier.

## Late finalize

You can declare a immutable symbol while not assign it with a value immediately by using keyword **late**.

It will become immutable after the first assignment.

```dart
late a
// print(a) // Error: [a] is not initialized yet.
a = 42
print(a)
// a = 'dragon' // Error: [a] is immutable.
```

## Const

You can declare a const int/float/string value by keyword 'const'.

```dart
const pi = 3.1415926
```

**You cannot declare a const expressions or functions for now. They are still WIP.**

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
