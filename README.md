# Hetu Script

## Introduction

[中文介绍](README_ZH.md)

A lightweight script language & its interpreter written purely in Dart, intended to be embedded in Flutter & Dart programs for purposes like hotfixes and game scripting.

It is kind of like lua but it is very easy to bind anything in Dart and make it easy to debug.

[Syntax referrence](HETU_SYNTAX.md)

[语法参考](HETU_SYNTAX_ZH.md)

In your Dart code, you can interpret an script file by this:

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HT_Interpreter();
  hetu.evalf('hello.ht', invokeFunc: 'main');
}
```

While 'hello.ht' is the script file written in Hetu, here is an example:

```typescript
// Define a class.
class Person {
  var name: String
  init (name: String) {
    this.name = name
  }
  fun greeting {
    print('Hi! I\'m', name)
  }
}

// This is where the script starts executing.
fun main {
  var ht = Person('Hetu')
  ht.greeting()
}
```

Hetu's grammar is almost same to typescript, except a few things:

- Function is declared with 'fun'.
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
  var hetu = HT_Interpreter(externalFunctions: {
    'hello': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return {'greeting': 'hello'};
    },
  });
  hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print(typeof(dartValue))
        dartValue['foo'] = 'bar'
        print(dartValue)
      }''', invokeFunc: 'main');
}
```

And the output should be:

```
Map<String, String>
{greeting: hello, foo: bar}
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
