---
title: Language - Hetu Script Language
---

# Syntax of Hetu Script Language

Hetu's grammar is close to most modern languages, it need very little time to get familar with.

Key characteristics of Hetu:

- Declarations starts with a keyword before the identifier: var, final, fun, construct, get, set, class, type, etc.
- Semicolon is optional. In most cases, the interpreter will know when a statement is finished. In rare cases, the lexer will implicitly add "end of statement token" (a semicolon in default lexicon) to avoid ambiguities. For example, before a line when the line starts with one of '++, --, (, [, {', or after a line when the line ends with 'return'.
- Type annotation is optional. Type is annotated **with a colon after the identifier** like typescript/kotlin/swift.
- Use **when** instead of **switch**

## Comments

```typescript
// This is a comment.
/* These are multi-line comments:
another line.*/
```

## Variable

Variable is declared with [var], [final]. The type annotation and initialize expression is optional.

```typescript
var person;
var fineStructureConstant: num = 1 / 137;
var isTimeTravelSuccessful: bool = true;
var skill: List = ['attack', 'defense'];
```

String literal can have interpolation the same to Javascript:

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

A little difference from Dart is that you have to write a curly brackets even if you have only one identifier.

## Type declaration

**WARNING: Type system is not fully implemented yet. It's more of a kind of annotation. You won't get analysis errors from them currently.**

Variables will be given a type if it has an initialize expression. And you cannot re-assign it with another type.

However, if you declare a variable with no initialize expression, the variable will be considered as having a **any** type (equals to dart's dynamic type).

```typescript
var name = 'naruto';
// name = 2020 // error!
```

- Type is a variable in Hetu, it can be assigned and returned.
- The type of a type is always 'type', no matter it's a primitive, instance, or function type.
- Use 'typeof' keyword to get the runtime type of a value.

```typescript
fun main {
  // decalre a function typedef
  type funcTypedef = fun(str) -> num
  // assign a function to a value of a certain function type
  var numparse: funcTypedef = fun(value: str) -> num { return num.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = fun { return typeof numparse }
  var funcTypedef2 = getType()
  // use this new type
  var strlength: funcTypedef2 = fun(value: str) -> num { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

## Function

Function is declared with **fun**, **get**, **set**, **construct**. The parameter list, return type and function body are all optional. For functions with no parameters, the empty brackets are also optional.

For a literal function expression, the function name is also optional if there's no type arguments and dart function typedef.

```typescript
fun doubleIt(n: num) -> num {
  return n * 2
}

fun main {
  def x = doubleIt(7) // expect 14
  print(x)
}
```

- For functions declared with **fun**, when no return type is provided in declaration, it will have a return type of **any**. And it will return null if you didn't write return statement within the definition body.
- Member functions can also be declared with **get**, **set**, **construct**, they literally means getter, setter and contructor function.
- If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty brackets.
- Function can have no name, it will then become a literal function expression (anonymous function).
- Functions can be nested, and nested functions can have names.
- Function are first class, you can use function as parameter, return value and store them in variables.
- Function body could be a block statement (within '{' and '}'), or a single line expression after '=>'.
- Return type is marked by a single arrow ('->') after the parameters brackets.
- Literal function could have no names, in this situation, the parameter brackets are not omittable.

```typescript
fun closure(func) {
  var i = 42
  fun nested {
    return i = i + 1
  }
  return nested
}

fun main {
  var func = closure( (n) => n * n )
  print(func()) // print: 1849
  print(func()) // print: 1936
}
```

## Class

- Class can have static variables and methods. Which can be accessed through the class name.
- Class's member functions use special keyword: **construct, get, set**, to define a constructor, getter, setter function.
- Constructors can be with no function name and cannot return values. When calling they will always return a instance.
- Getter & setter functions can be used feels like a member variable. They can be accessed without brackets.
- Use 'extends' to inherits other class's members

```typescript
// class definition
class Calculator {
  // instance member
  var x: num
  var y: num
  // static private member
  static var _name = 'the calculator'
  // static get function
  static get name -> str {
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
  fun meaning -> num {
    // when no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

## Struct

Struct are a prototype base object system. This is mainly borrowed from Javascript.

### Named struct

Named struct's declaration are like class, you can have constructors, getter and setters.

```javascript
struct Named {
  var name: str
  construct (name: str) {
    this.name = name
  }
}

var n = Named('jimmy')
```

### Literal struct

Literal struct are expressions in the form of '{key: value}'

```javascript
var obj = {
  name: 'jimmy'
  age: 17
}
```

The key must be either a identifier, or a string literal (not includes string interpolation).

Struct are different from class, that you wont get errors when you visit a non-exist member.

```javascript
obj.race = 'dragon'; // okay, this will define a new member on obj.
var lvl = obj.level; // okay, although lvl's value will be null
```

- Struct's prototype can be accessed and modified through '$prototype'.
- Struct's root prototype has two functions: toString() and toJson(). Can be used to easily convert a struct into other code.

## Control flow

Hetu has while, do loops, and classic for(init;condition;increment) and for...in loops. As well as when statement, which works like switch.

```javascript
fun main {
  var i = 0
  for (;;) {
    ++i
    when (i % 2) {
      0 -> print('even:', i)
      1 -> print('odd:', i)
      else -> print('never going to happen.')
    }
    if (i > 5) {
      break
    }
  }
}
```

### If

- 'if' statement's branches could be a single statement without brackets.
- 'if' can also be an expression which will have a value, in this case else branch is not omitable.

```javascript
if (condition) {
  ...
} else {
  ...
}
```

### While

```javascript
while (condition) {
  ...
}
```

### Do

- 'do' statement's 'while' part is optional, if omitted, it will become a anonymous namespace.

```javascript
do {
  ...
} while (condition)
```

### Truth value

If the interpreter is in non strict mode, the if/do/while statement's condition expression will be inexplicitly converted to boolean.

The conversion rules is:

```dart
if (condition == null ||
    !condition ||
    condition == 0 ||
    condition == '' ||
    condition == '0' ||
    condition == 'false' ||
    (condition is List && condition.isEmpty) ||
    (condition is Map && condition.isEmpty) ||
    (condition is HTStruct && condition.isEmpty)) {
  return false;
} else {
  return true;
}
```

### For

- 'for' statement's expr must be separated with ';'.
- The expression itself is optional. If you write 'for ( ; ; )', it will be the same to 'while (true)'
- When use for...in, the loop will iterate through the keys of a list.

```dart
for (init; condition; increment) {
  ...
}

for (var item in list) {
  ...
}
```

### When

When is the substitue for 'switch' in older programming languages, we change its name to indicate more complex usages.

- 'when' statement's condition is optional. If not provided, the interpreter will check the cases and jump to the first branch if the expression evaled as true. In this case, the when statement is more like a if else statement except with a little more efficiency because it won't go through every branch.
- 'when' statement's case could be non-const expression or variables;
- 'when' statement's body must be enclosed in curly brackets. However, the case branch could be a single statement without brackets;
- 'when' statement's else branch is optional.

```javascript
when (condition) {
  expr -> expr // ...single expression...
  expr -> {
    // ...block statement...
  }
  // will not fall through here
  else -> {
    // ...
  }
}
```

## Spread syntax

You can use spread syntax ('...') in three places:

### Variadic parameter

In function declaration's parameters. This means you can pass as many positional arguments as you wish.

```javascript
external fun print(... args: any)

print('hello', 'world!', 42) // okay!
```

### Function call argument

In function call's arguments. This means to 'spread' the list object here to fill in the positional argument list.

```javascript
fun someFunc(a, b) {
  print(a + b)
}
var list = [5, 6]
someFunc(...list) // same to 'someFunc(5, 6)'
```

### List literal

In list literal's value list, This means to 'spread' the list object here to fill in the items.

```javascript
var list = [5, 6];
var ht = [1, 2, ...[3, 4], ...list]; // same to [1, 2, 3, 4, 5, 6]
```

### Struct literal

In struct literal's value list, This means to 'spread' the struct object here to fill in the field.

```javascript
var name = {
  familyName: 'Hord',
  firstName: 'Luk',
};
var person = {
  ...name,
  age: 23,
};
// same to:
// {
//   familyName: 'Hord',
//   firstName: 'Luk',
//   age: 23
// }
```

## Keywords

Some of the keywords only used in specific places, hence can be used as normal identifiers (variable names & class members, etc.).
Some of the keywords have no meaning right now, they are reserved for future development.

null, true, false, var, final, const, typeof, class, enum, fun, struct, interface, this, super, abstract, override, external, static, extends, implements, with, construct, factory, get, set, async, break, continue, return, for, in, of, if, else, while, do, when, is, as

## Operator precedence

| Description    | Operator                  | Associativity | Precedence |
| :------------- | :------------------------ | :-----------: | :--------: |
| Unary postfix  | e., e++, e--, e1[e2], e() |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e          |     None      |     15     |
| Multiplicative | \*, /, %                  |     Left      |     14     |
| Additive       | +, -                      |     Left      |     13     |
| Relational     | <, >, <=, >=, as, is, is! |     None      |     8      |
| Equality       | ==, !=                    |     None      |     7      |
| Logical AND    | &&                        |     Left      |     6      |
| Logical Or     | \|\|                      |     Left      |     5      |
| Conditional    | e1 ? e2 : e3              |     Right     |     3      |
| Assignment     | =, \*=, /=, +=, -=        |     Right     |     1      |
