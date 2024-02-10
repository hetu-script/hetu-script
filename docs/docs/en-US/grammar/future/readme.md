# Future, async & await

It is possible for an external function to return a Future value.

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
      external function fetch
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

And you could also create a async function by add `async` keyword before its definition block:

```dart
// for declaration
function testAsync async {
  // some code
}

// for literal function
() async {
  // some code
} ().then((value) {
  // you can immediately call this future literal function to do things just like in Javascript.
})

```

Hetu will create a Future object by using the script function as its argument.

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

## await

After Hetu version 0.5.0, it possible to use await keyword within async function to avoid complex `then` callbacks.

However, this is an experimental feature, and it's only partly supported.

You can now use await in expressions statement (like a function call statement), variable declaration initialization,

but you still cannot use await within For statement initialization or a function call's arguments in this version.

Example:

```dart
final result = await fetch() * await valueFuture() * await sumAll();
```
