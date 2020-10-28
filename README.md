# Hetu Script

## Introduction

Hetu is a lightweight script interpreter written in Dart, intended to be embedded in Dart programs.

It is kind of like lua but free of ffi c bindings and make it easy to debug.

In your Dart code, you can interpret an script file by this:

```typescript
import 'package:hetu_script/hetu.dart';

void main() async {
  // init the Hetu Environment
  var hetu = await HetuEnv.init();
  hetu.evalf('hello.ht', invokeFunc: 'main');
}
```

While 'hello.ht' is the script file written in Hetu, here is an example:

```typescript
// Define a class.
class Person {
    // Define a member function.
    proc greeting(name: String) {
      // Print to console.
      print('hello ', name)
    }
}

// This is where the script starts executing.
proc main {
  // Declare and initialize variables.
  let number = (6 * 7).toString()
  let jimmy = Person()
  jimmy.greeting(number);
}
```

Hetu's grammar is almost same to typescript, except a few things:

- Function is declared with 'fun' or 'proc', the latter means procedure and doesn't return value.
- Variable declared with keyword 'let' without a type will be given a type if it has an initialization.

## Binding

To call Dart functions in Hetu, just init Hetu with 'externalFunctions'.

Then define those dart funtion in Hetu with 'external' keyword.

Then you can call those functions in Hetu.

```typescript
void main() {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, List<dynamic> args) {
      print('hello from dart');
      if (args.isNotEmpty) for (final arg in args) print(arg);
    },
  });
  hetu.eval(
      'external fun dartHello\n'
      'proc main {\n'
      'dartHello("from hetu")\n'
      '\n}',
      invokeFunc: 'main');
}
```

## Command line tool

On Windows, there is a hetu.exe under project directory to use in Command line.

Usage:

```
hetu [-r] [file_name] [invoke_name]
```

If [-r] option is provided, enter REPL mode.

If [invoke_name] is provided, will switch to program style and call function with given name.

Otherwise interpret the file as a script.
