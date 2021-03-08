# Hetu Script

## Introduction

Hetu is a lightweight script interpreter written in Dart, intended to be embedded in Dart programs.

It is kind of like lua but free of ffi c bindings and make it easy to debug.

[Full Hetu syntax description.](HETU_SYNTAX.md)

In your Dart code, you can interpret an script file by this:

```typescript
import 'package:hetu_script/hetu_script.dart';

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
- Variable declared with keyword 'def' or 'let' and without a type will be given a type if it has an initialization.

## Binding

To call Dart functions in Hetu, just init Hetu with 'externalFunctions'.

Then define those dart funtion in Hetu with 'external' keyword.

Then you can call those functions in Hetu.

You can pass object from Dart to Hetu by the return value of external functions.

You can pass object from Hetu to Dart by the return value of Interpreter's [invoke] function;

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, Map<String, dynamic> args) {
      return {'dartValue': 'hello'};
    },
  });
  hetu.eval(
      'external fun dartHello\n'
      'proc main {\n'
      '  var dartValue = dartHello()\n'
      '  print(typeof(dartValue))\n'
      '  dartValue[\'foo\'] = \'bar\'\n'
      '  print(dartValue)'
      '\n}',
      invokeFunc: 'main');
}
```

And the output should be:

```
Map<String, String>
{dartValue: hello, foo: bar}
```

## Command line tool

On Windows, there is a hetu.exe under project directory to use in Command line.

Usage:

```
hetu [file_name] [invoke_func]
```

If no option is provided, enter REPL mode.

In REPL mode, everything you entered will be evaluated and print out immediately.

```typescript
>>>var a = 42
42
```

If you want to write multiple line in REPL mode, use '\\' to end a line.

```typescript
>>>fun hello {\
return 6 * 7} // press enter
function hello(): any // repl print
>>>hello()
42 // repl print
>>>
```

If [file_name] is provided, evaluate the file in function mode.

If [invoke_name] is provided, evaluate the file in library mode and call a certain function with given name.
