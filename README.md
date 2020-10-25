# Hetu Script

Hetu is a lightweight script interpreter, intended to be embedded in Dart programs. It is kind of like lua but free of ffi c bindings and make it easy to debug.

## Hello World

In your Dart code, you can interpret an script file by this:

```typescript
import 'package:hetu_script/hetu.dart';

void main() async {
  var hetu = await HetuEnv.init();
  await hetu.evalf('hello.ht', invokeFunc: 'main');
}
```

While 'hello.ht' is the script file written in Hetu, here is an example:

```typescript
// Define a class.
class Person {
    // Define a member function.
    fun greeting(name: String) {
      // Print to console.
      print('hello ', name)
    }
}

// This is where the script starts executing.
fun main {
  // Declare and initialize variables.
  let number = (6 * 7).toString()
  let jimmy = Person()
  jimmy.greeting(number);
}
```

Hetu's grammar is almost same to typescript, except a few things:

- Function is declared with 'fun'.
- Variable declared with keyword 'let' without a type will be given a type if it has an initialization.