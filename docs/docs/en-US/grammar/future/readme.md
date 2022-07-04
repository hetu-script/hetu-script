# Future, async & await

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
  final hetu = Hetu();
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

## Create a Future

After 0.4.0, you can manually create a Future object by using the constructor of the Future class binding:

```dart
final a = Future( () => 42 )
a.then( (value) => print(value) )
print(41)
```

The above output should be 41 then 42.

## Wait for a list of future

After 0.4.0, you can use the static wait api on Future class to wait for a bunch of values to be returned.

```dart
async asyncFunc1 => 41
async asyncFunc2 => 42

Future.wait([asyncFunc1(), asyncFunc2()]).then((valueList) {
  print(valueList)
})
```

Above code will print:

```
[
  41,
  42
]
```
