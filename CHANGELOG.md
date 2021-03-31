## 0.1.0+1

- Feat: String interpolation. Example:

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

## 0.1.0

- Feature: Now fully support nested function and literal function. Example:

```typescript
fun closure(func) {
  var i = 42
  fun nested () {
    i = i + 1
    print(func(i))
  }
  return nested
}

fun main {
  var func = closure( fun (n) { return n * n } )
  func() // print: 1849
  func() // print: 1936
}
```

- Feature: Added ++, -- post and pre operators, and +=, -=, \*=, /= operators.
- Feature: Full support on While, Do loops, classic for(init;condition;increment), for...in/of, when statement (works like switch).

Loops and When statement example:

```dart
fun main {
  var i = 0
  for (;;) {
    ++i
    when (i % 2) {
      0: print('even:', i)
      1: print('odd:', i)
      else: print('never going to happen.')
    }
    if (i > 5) {
      break
    }
  }
}
```

The output is:

```
odd: 1
even: 2
odd: 3
even: 4
odd: 5
even: 6
```

- Feature: Ternary operator: 'conditon ? true : false'.
- Feature: Interpreter function for bind Dart Function Typedef. Example:

In Hetu script:

```dart
fun [DartFunction] add(a: num, b: num): num {
  return a + b
}

fun getFunc {
  return add
}
```

Then when you evaluate this [add] function in Hetu, you will get a native Dart function.

```dart
typedef DartFunction = int Function(int a, int b);

int hetuAdd(DartFunction func) {
  var func = hetu.invoke('getFunc');
  return func(6, 7);
}
```

You have to bind the Dart typedef in [Interpreter.init] before you can use it.

```dart
await hetu.init(externalFunctions: {
  externalFunctionTypedef: {
  'DartFunction': (HTFunction function) {
    return (int a, int b) {
      // must convert the return type here to let dart know its return value type.
      return function.call([a, b]) as int;
    };
  },
});
```

## 0.0.5

- Refactor: Migrate to null safety.

- Feature: Literal function expression (anonymous function). Usage:

```typescript
  fun closure(func) {
    var i = 42
    fun nested () {
      i = i + 1
      return (func(i))
    }
    return nested
  }
  fun main {
    var func = literalFunction( fun (n) { return n * n } )
    func()
    func()
  }
```

- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.

## 0.0.2+1

- Added multiline comment.

## 0.0.1

- Initial version, hello world!
