## 0.1.0

- Feature: Changed default interpreter to a bytecode evaluater.
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
- Feature: Added full support on While, Do loops, and both classic for(init;condition;increment) and for...in/of.
- Feature: Added When statement, works like switch.

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

- Feature: Added Ternary operator: 'conditon ? true : false'.
- Feature: Added new interpreter function for bind Dart Function Typedef.

The output is:

```
odd: 1
even: 2
odd: 3
even: 4
odd: 5
even: 6
```

## 0.0.6

- Feature: Error & import are now handle by plugins.
- Change: [evalf] function of interpreter now changed into [import]
- Change: External static members' id unified into [className.varName] in binding.

## 0.0.5

- Refactor: Migrate to null safety.
- Refactor: Redesigned the binding (external classes, functions and variables).
- Refactor: Redesigned the error handling.

## 0.0.4

- Feature: External class.
- Refactor: Build-in dart types.

## 0.0.3

- Feature: Literal function expression (anonymous function). Usage:

```typescript
fun main {
  var func = fun (name: str) {
    return name + '_postfix'
  }

  print(func())
}
```

- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.
- Fixed class extends, member override and inheritance.
- Fixed import statement.

## 0.0.2+4

- Fixed bug in method calling of instances.
- Fixed bug of optional function parameters.
- Fixed bug of import statement.
- Fixed bug of member get from super classes.
- Fixed bug of method expression resolving.

## 0.0.2+1

- Added some comments in the dart source file.
- Added some test for error handling.
- Added multiline comment.
- Changed 'HetuEnv' into 'Hetu'.
- Fixed bugs in method calling of instances.

## 0.0.2

- Fixed core library loading issue, no longer use outside source files.
- Changed lisence from GNU GPLv3 to MIT.

## 0.0.1

- Initial version, hello world!
