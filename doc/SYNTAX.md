# Hetu Script

Hetu's grammar close to most modern languages, hence need very little time to get familar with.

Key point:

- Semicolon is optional.
- Type check and annotation is optional.
- Type is annotated with a colon after the identifier (like typescript/kotlin/swift).

## Script file structure

Hetu script files has two main structure, controlled by the ParseStyle parameter in eval function of an Interpreter object.

- [ParseStyle.library]: the file contains only import statement and declarations(variable, function and class). Interpreter will call the function name given by parameter [invokeFunc]. This is like most app structure in C++, Java and Dart.

- [ParseStyle.function]: the file is a anonymous function body, contains all kinds of expression and control statement. Everything is immediately evaluated. This is like the usage of Python.

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

| Description    | Operator         | Associativity | Precedence |
| -------------- | ---------------- | ------------- | ---------- |
| Unary postfix  | e., e()          | None          | 16         |
| Unary prefix   | -e, !e           | None          | 16         |
| Multiplicative | \*, /, %         | Left          | 14         |
| Additive       | +, -             | Left          | 13         |
| Relational     | <, >, <=, >=, is | None          | 8          |
| Equality       | ==, !=           | None          | 7          |
| Logical and    | &&               | Left          | 6          |
| Logical or     | \|\|             | Left          | 5          |
| Assignment     | =                | Right         | 1          |

## Variable

Variable is declared with 'var', 'def' or 'let'. The type and initialize expression is optional.

```typescript
var person;
var name = 'naruto';
var year = 2020;
var fineStructureConstant: num = 1 / 137;
var isTimeTravelSuccessful: bool = true;
var gasGiants = ['Jupiter', 'Saturn'];
var skill: Map<String> = {
  tags: ['attack'],
  script: '//path/to/skill_script.ht',
};
```

If declared with 'var', variables will have a type of 'any', hence you can re-assign it with any type.

```typescript
var name = 'naruto';
name = 2020; // not an error
```

If declared with 'let', variables will be given a type if it has an initialize expression. And you cannot re-assign it with another type.

```typescript
let name = 'naruto';
// name = 2020 // error!
```

If declared with 'const', variables has to have an initialize expression, and it will be given a type according to the expression, and it will become immutable(in other words this is a constant).

```typescript
const name = 'naruto';
// name = "sasuke" // error!
```

## Type declaration

Typename is not evaluated when declared, hence you can declare a variable with an non-exist type. However if you do this, you cannot assign it with any value.

```typescript
var i: NotAType; // not an error
```

## Control statement

```typescript
if (year >= 2001) {
  print('21st century');
} else if (year >= 1901) {
  print('20th century');
} else {
  print('unkown date');
}

for (var planet in gasGiants) {
  print(planet);
}

while (year < 2040) {
  year = year + 1;
}
```

## Function

Function is declared with 'fun', 'get', 'set', 'construct'. the function name, parameter list, return type and function body are all optional. For functions with no parameters, the empty brackets are also optional.

```typescript
fun doubleIt(n: num): num {
	return n * 2
}

fun main {
  def x = doubleIt(7) // expect 14
  print(x)
}
```

For functions declared with 'fun', when no return type is provided in declaration, it will have a return type of 'any'. And it will return null if you didn't write return statement within the definition body.

Member functions can also be declared with 'get', 'set', 'construct', they literally means getter, setter and contructor function.

If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty brackets.

Functions can be passed as arguments and be return value from another function.

Function can have no name, it will then become a literal function expression(anonymous function).

```typescript
fun foo(){
  var i = 42
  var bar = fun () {
    return i
  }
  return bar
}

fun main {
  var func = foo()
  print(func()) // Will print 42.
}
```

In Hetu, functions are first class, you can use function as parameter, return value and store them in variables. Example:

```typescript
fun closure(func) {
  var i = 42
  return fun () { print(func(i)) }
}

fun main {
  var func = closure( fun (n) { return n * n } )
  func() // Output: 1764
}
```

As shown above, the grammar of literal function (anonymous function) are just like normal functions but without a name.

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
  static get name: String {
    // 类中的静态函数只能访问类中的静态对象
    return _name
  }

  // static set function
  static set name(new_name: String) {
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
    // when no shadowing, `this` keyword is omittable
    return x * y
  }
}
```

# Import

Use import statement to import content from another script file.

```dart
import 'hello.ht'

fun main {
  hello()
}
```
