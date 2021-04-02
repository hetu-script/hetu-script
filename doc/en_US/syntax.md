# Hetu Script

Hetu's grammar close to most modern languages, hence need very little time to get familar with.

Key characteristics of Hetu:

- Optional semicolon: In most cases, the interpreter will know when a statement is finished. However, in rare cases, the lexer will implecitly add semicolon to avoid ambiguities. For example, before a line when the line starts with one of '++, --', or after a line when the line ends with 'return'.

- Optional type annotation and checking. Type is annotated with a colon after the identifier like typescript/kotlin/swift.
- Use [when] instead of [switch]

## Script file structure

Hetu script files has two main structure, controlled by the ParseStyle parameter in eval function of the Interpreter.

- [ParseStyle.library]: the file contains only import statement and declarations(variable, function and class). Interpreter will call the function name given by parameter [invokeFunc]. This is like most app structure in C++, Java and Dart.

- [ParseStyle.function]: the file is a anonymous function body, contains all kinds of expression and control statement. Everything is immediately evaluated. This is like the usage of most script languages like Javascript, Python and Lua.

## Comments

```typescript
// This is a comment.
/* These are multi-line comments:
another line,
end here.*/
```

## Keywords

null, static, var, def, let, any, namespace, as, class, data, interface, mixin, fun, construct, get, set, this, super, extends, implements, mixin, external, import, break, continue, for, in, if, else, return, while, when, is

## Operators

| Description    | Operator               | Associativity | Precedence |
| :------------- | :--------------------- | :-----------: | :--------: |
| Unary postfix  | e., e(), e[], e++, e-- |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e       |     None      |     15     |
| Multiplicative | \*, /, %               |     Left      |     14     |
| Additive       | +, -                   |     Left      |     13     |
| Relational     | <, >, <=, >=, is, is!  |     None      |     8      |
| Equality       | ==, !=                 |     None      |     7      |
| Logical AND    | &&                     |     Left      |     6      |
| Logical Or     | \|\|                   |     Left      |     5      |
| Conditional    | e1 ? e2 : e3           |     Right     |     3      |
| Assignment     | =, \*=, /=, +=, -=     |     Right     |     1      |

## Variable

Variable is declared with [var], [let] or [const]. The type annotation and initialize expression is optional.

```typescript
var person;
var fineStructureConstant: num = 1 / 137;
var isTimeTravelSuccessful: bool = true;
var skill: Map<str> = {
  tags: ['attack'],
  script: '//path/to/skill_script.ht',
};
```

If declared with [var], variables will have a type of [any] if the type annotation is omitted, hence you can re-assign it with any type.

```typescript
var name = 'naruto';
name = 2020; // not an error
```

If declared with [let], variables will be given a type if it has an initialize expression. And you cannot re-assign it with another type.
However, if you declare a variable with [let] and with no initialize expression, the variable will still considered a dynamic [any] type.

```typescript
let name = 'naruto';
// name = 2020 // error!
```

If declared with [const], variables has to have an initialize expression, and it will be given a type according to the expression, and it will become immutable(in other words this is a constant).

```typescript
const name = 'naruto';
// name = "sasuke" // error!
```

String literal can have interpolation the same to Javascript:

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

A little difference from Dart is that you have to write a curly brackets even if you have only one identifier.

## Type declaration

Typename is not evaluated when declared, hence you can declare a variable with an non-exist type. However if you do this, you cannot assign it with any value.

```typescript
var i: NotAType; // not an error
```

## Control statement

Hetu has While, Do loops, and classic for(init;condition;increment) and for...in/of loops. As well as When statement, which works like switch.

Check the [control flow](https://github.com/hetu-script/hetu-script/blob/master/doc/en_US/control_flow.md) page for more information

```typescript
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

## Function

Function is declared with [fun], [get], [set], [construct]. the function name, parameter list, return type and function body are all optional. For functions with no parameters, the empty brackets are also optional.

```typescript
fun doubleIt(n: num): num => n * 2

fun main {
  def x = doubleIt(7) // expect 14
  print(x)
}
```

For functions declared with [fun], when no return type is provided in declaration, it will have a return type of [any]. And it will return null if you didn't write return statement within the definition body.

Member functions can also be declared with [get], [set], [construct], they literally means getter, setter and contructor function.

If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty brackets.

Function can have no name, it will then become a literal function expression(anonymous function).

Functions can be nested, and nested functions can have names.

Function are first class, you can use function as parameter, return value and store them in variables.

Function can write in forms with fun => <expr> when there's only one exression as the body.

```typescript
fun closure(func) {
  var i = 42
  fun nested => i = i + 1
  return nested
}

fun main {
  var func = closure( fun (n) => n * n )
  print(func()) // print: 1849
  print(func()) // print: 1936
}
```

## Class

Class can have static variables and methods. Which can be accessed through the class name (rather than a instance).

Class's member functions (methods) can use keyword: construct, get, set to define a constructor, getter, setter function.

Constructors have no function names and cannot return values. They will return a instance.

Getter & setter functions can be used as a member variable. They can be accessed without brackets.

```typescript
// class definition
class Calculator {
  // instance member
  var x: num
  var y: num
  // static private member
  static var _name = 'the calculator'
  // static get function
  static get name: str {
    return _name
  }
  // static set function
  static set name(new_name: str) {
    _name = new_name
  }
  // static function
  static fun greeting {
    print('hello! I\'m ' + name)
  }
  // constructor with parameters
  construct (x: num, y: num) {
    // use this to access instance members with same names
    this.x = x
    this.y = y
  }
  // method with return type
  fun meaning: num {
    // when no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

# Import

Use import statement to import content from another script file.

```dart
import 'hello.ht'

fun main => hello()
```
