---
title: Advanced topics - Hetu Script Language
---

# Advanced topics

## Null check

The script is not planning to introduce null safety. However, there are some syntax to help do null check:

```dart
var a // a is null
// Nullable member get:
final value = a?.value // value is null and we won't get errors
// If null then get another value
final text = a ?? 'hi!' // text is 'hi!'
// If null then assign
a ??= 42
print(a) // a is 42 now
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
  ''', isScript: true);
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
