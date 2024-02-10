# Syntax of Hetu Script Language

Hetu's grammar is close to most modern languages, with a few key characteristics:

## Declaration keyword first

Declarations starts with a keyword before the identifier: var, final, const, function, constructor, get, set, class, type, etc.

## Semicolon

Semicolon is optional. In most cases, the interpreter will know when a statement is finished. In rare cases, the lexer will implicitly add "end of statement token" (a semicolon in default lexicon) to avoid ambiguities. For example, before a line when the line starts with one of '++, --, (, [, {', or after a line when the line ends with 'return'.

## Type annotation writes after identifiers

Type annotation is optional. Type is annotated **with a colon after the identifier** like typescript/kotlin/swift.

## Some keyword are different

**switch** do not need `case` and `break` keywords, and with [more complex usage](control_flow/readme.md#switch) to match the condition value.

## Comments

Normal comments:

```typescript
// This is a comment.
/* These are multi-line comments:
another line.*/
```

Documentation comments:

```typescript
/// This is a documentation comment
function myFunc() -> int {
  // some code
}
```

## Private members

You can specify a private member of a class/namespace/source by making its name starts with '\_'.

```dart
class Person {
  var _name
  constructor (name) {
    _name = name
  }
  function greeting {
    print('Hi, I\'m ', _name)
  }
}
final p = Person('jimmy')
// print(p._name) // Error!
p.greeting()
```

## Expression, statement

In hetu, variable declaration and variable assignment are both expression, which have the value of the assignment expression. It's possible to write code like:

```dart
if (a = fetch()) {
  // ...
}
```

The if statement will run if the value of a if [truthy](strict_mode/readme.md#truth-value).

# Block of code

For blocks of code (function body), Hetu will implicitly return the last expression.

The function below:

```javascript
function test(n) {
  var x = n * 2;
}
```

will return the value of x.
