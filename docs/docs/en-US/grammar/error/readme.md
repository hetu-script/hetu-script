# Error & exception

You can manually throw a Dart exception within the script using the **assert** or **throw** keyword.

## assert

```dart
assert(1 > 5)
```

Will throw an `AssertionError`. The error message will contain the source code text in the parentheses to help you understand why it failed.

The expression within the parentheses must be a boolean value.

assertions can be stripped from compiled bytecode by setting `removeAssertion: true` in the Hetu config.

## throw

```dart
var i = 42
throw 'i is ${i}!'
```

Will throw a `script throws` error. The error message will contain the toString() value of the expression after the keyword.

You must provide an expression after `throw`, although the value may be null.

## Common runtime errors

The interpreter reports errors with source location information (file, line, column) when `processError` is enabled in the config. Common runtime errors include:

| Error code | Cause |
|-----------|-------|
| `undefined` | Accessing a variable or identifier that has not been declared |
| `notInitialized` | Accessing a `late` variable before its first assignment |
| `immutable` | Reassigning a `final`, `const`, or `late` variable |
| `arity` | Calling a function with the wrong number of positional arguments |
| `argType` | Passing an argument of the wrong type (when runtime type checking is enabled) |
| `notCallable` | Attempting to call a non-function value |
| `undefinedMember` | Accessing a non-existent member on a class instance |
| `outOfRange` | List index out of bounds |
| `typeCast` | Invalid type cast with `as` operator |
| `circleInit` | Variable initialization references itself |
| `notSpreadableObj` | Spreading a non-iterable, non-struct value |
| `callNullObject` | Attempting to call a method on `null` |
| `subGetKey` | Invalid subscript key type |

## Error handler configuration

The `InterpreterConfig` provides several options for controlling error output:

- **processError** (default: `true`): When enabled, errors are augmented with source file, line, and column information before being re-thrown.
- **showHetuStackTrace** (default: `false`): Include the Hetu script call stack in error output.
- **showDartStackTrace** (default: `false`): Include the Dart host call stack in error output.
- **stackTraceDisplayCountLimit** (default: `5`): Maximum number of stack frames to display.

## Error handling

The script does not support `try...catch` functionality. It is recommended to handle errors in Dart code rather than within the script.
