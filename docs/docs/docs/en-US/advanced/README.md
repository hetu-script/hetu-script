---
title: Advanced topics
---

# Advanced topics

## Private members

You can specify a private member of a class/namespace/source by making its name starts with '\_'.

```dart
class Person {
  var _name
  construct (name) {
    _name = name
  }
  fun greeting {
    print('Hi, I\'m ', _name)
  }
}
final p = Person('jimmy')
// print(p._name) // Error!
p.greeting()
```

## Big integers

The builtin integers in script are int32, which range from -2,147,483,648 to 2,147,483,647. This is due to the limitation of the runtime.js of Dart.

To manipulate bigger numbers, you can use preincluded class BigInt.

```dart
final bi = BigInt.parse("9223372036854775807")
```

## Null check

The script is not planning to introduce null safety. However, there are some syntax to help do null check:

```dart
var a // a is null
// Nullable member get:
final value = a?.value // value is null and we won't get errors
final result = a?() // nullabla function call
// If null then get another value
final text = a ?? 'hi!' // text is 'hi!'
// If null then assign
a ??= 42
print(a) // a is 42 now
```

The nullable check will pass to next unary postfix operator like a chain:

```dart
var a // a is null
final value = a?.collection[0].value() // value is null and we won't get errors
```

## Future

All hetu functions are sync. The script do not support async/await functionality, and we are not planning to do so in the near future.

However, it is possible for an external function to return a Future value.

To make things easy, we added a simple wrapper for Dart's Future object. You can use the 'then' method to do something when the Dart Future is completed.

Example:

```dart
import 'package:hetu_script/hetu_script.dart';

Future<void> fetch() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(
      const Duration(seconds: 2), () => print('Hello world after 2 seconds!'));
}

void main() {
  var hetu = Hetu();
  hetu.init(externalFunctions: {'fetch': fetch});
  hetu.eval(r'''
      external fun fetch
      final future = fetch()
      future.then((value) {
        print('future completed!')
      })
  ''');
}
```

## Error hanlding

It's not recommended to try to handle error in the script. You should do this in the Dart code.

The script doesn't support 'try...catch' functionality. However, it's possible to throw a error within the script using the Assert keyword.

For example, a statement like:

```dart
assert 1 > 5
```

Will throw an 'assertion failed' error. And the error message will contain the expression string after the keyword to let you know why this happened.

The expression after assert must be a boolean value.

## Automatic semicolon insertion

Automatic semicolon insertion (ASI) is a technique in programming languages that semicolon is optional. [Click here for more information](https://en.wikibooks.org/wiki/JavaScript/Automatic_semicolon_insertion).

If a language has no semicolon and in the same time it also allows for multiline expression. Then there will be times that ambiguity happens.

For example:

```javascript
function getObject() {
  if (isReady) return; // a semicolon will always be inserted here automatically by javascript engine
  {
    // fields
  }
  // some codes
}
```

If there's no ASI, we would never know wether the language use want to return the object after it, or they just want to start a new line after the return keyword.

Similar things also happens when you started a line with brackets, and the interpreter will not knowing if you want to get the subscript value out of the object in the previous line.

In Hetu script, the ASI is slightly different from Javascript's approach (which almost will always add the semicolon).

We would add a 'end of statement mark' after a line, only if the next line starts with one of these tokens '{', '(', '[', '++', '--', **AND** this line is not an **UNFINISHED** line that ends with one of these tokens: '!', '\*', '/', '%', '+', '-', '<', '<=', '>', '>=', '=', '!=', '??', '&&', '||', '=', '+=', '-=', '\*=', '/=', '??=', '.', '(', '{', '[', ',', ':', '->', '=>'.

And Hetu will always add a 'end of statement mark' after return if there's a new line.

So if you would like to return the value, remember to make the left bracket same line with the return.

And if you want to write function definition, remember to make the left bracket same line with the function parameters.
