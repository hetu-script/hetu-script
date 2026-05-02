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

After Hetu version 0.5.0, it is possible to use the `await` keyword within async functions to avoid complex `then` callbacks.

The `await` keyword is fully implemented. Within an async function or script, `await` suspends execution until the Future resolves. The interpreter saves and restores the full execution context (including the instruction pointer, namespace, and operand stack), so `await` works correctly inside nested function calls, loops, and conditional branches.

Example:

```dart
async function fetchData {
  final a = await fetch()
  final b = await valueFuture()
  return a + b
}
```

```dart
final result = await fetch() * await valueFuture() * await sumAll();
```

### Where await is supported

The `await` keyword works in all expression contexts — including list literals, struct literals, string interpolation, function call arguments, switch case values, arithmetic expressions, and variable initializers within scripts and function bodies.

The only contexts where `await` is **not** supported are:

- **Module (.ht) top-level variable initializers** — Module-level variables use lazy initialization, which cannot suspend for `await`. Use a function instead.
- **Named struct member initializers** (including `static var` fields and instance field defaults) — Struct construction is synchronous.
- **Function parameter default values** — The analyzer rejects `await` in parameter defaults at compile time.

Note that `await` in an `async` function's parameter defaults would also not make semantic sense, since the default value is evaluated during argument resolution, before the function body's async context is active.

```dart
// In a module (.ht), don't do this:
// final x = await fetch()

// Instead, use a function:
function init async {
  final x = await fetch()
}
```

### How await works internally

When the interpreter encounters an `await` expression, it checks whether the top of the operand stack is a Dart `Future`. If so, it saves the current execution context (instruction pointer, namespace, stack frames) into a `FutureExecution` object and suspends. Once the Future completes, the interpreter resumes execution from the saved context with the resolved value. This process repeats for chained Futures until no more pending Futures remain.
