---
title: Advanced topics - Hetu Script Language
---

# Advanced topics

## Future

The script is single threaded and all functions are sync. We do not support making futures within the script, and not planning to do so.

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