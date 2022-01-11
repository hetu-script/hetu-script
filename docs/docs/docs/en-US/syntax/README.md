# Syntax of Hetu Script Language

Hetu's grammar is close to most modern languages, with a few key characteristics:

Declarations starts with a keyword before the identifier: var, final, const, fun, construct, get, set, class, type, etc.

Semicolon is optional. In most cases, the interpreter will know when a statement is finished. In rare cases, the lexer will implicitly add "end of statement token" (a semicolon in default lexicon) to avoid ambiguities. For example, before a line when the line starts with one of '++, --, (, [, {', or after a line when the line ends with 'return'.

Type annotation is optional. Type is annotated **with a colon after the identifier** like typescript/kotlin/swift.

Use **when** instead of **switch**

## Comments

```typescript
// This is a comment.
/* These are multi-line comments:
another line.*/
```

## Variable

Variable is declared with 'var', 'final', 'late'. The type annotation and initialize expression is optional.

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

### Late finalize

You can declare a immutable symbol while not assign it with a value immediately by using keyword **late**.

It will become immutable after the first assignment.

```dart
late a
// print(a) // Error: [a] is not initialized yet.
a = 42
print(a)
// a = 'dragon' // Error: [a] is immutable.
```

## Const

You can declare a const int/float/string value by keyword 'const'.

```dart
const pi = 3.1415926
```

**You cannot declare a const expressions or functions for now. They are still WIP.**

## Shadowing

It is possible to shadow a variable by defining another variable with the same name.

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## Delete

It is possible to delete a variable using 'delete' keyword.

```dart
var a = 42
delete a
print(a) // error: a is undefined!
```

## Type declaration

**WARNING: Type system is not fully implemented yet. It's more of a kind of annotation. You won't get analysis errors from them currently.**

Variables will be given a type if it has an initialize expression. And you cannot re-assign it with another type.

However, if you declare a variable with no initialize expression, the variable will be considered as having a **any** type (equals to dart's dynamic type).

```typescript
var name = 'naruto';
// name = 2020 // error!
```

Type is a variable in Hetu, it can be assigned and returned.

The type of a type is always 'type', no matter it's a primitive, instance, or function type.

Use 'typeof' keyword to get the runtime type of a value.

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

For functions declared with **fun**, when no return type is provided in declaration, it will have a return type of **any**. And it will return null if you didn't write return statement within the definition body.

Member functions can also be declared with **get**, **set**, **construct**, they literally means getter, setter and contructor function.

If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty brackets.

Functions can be nested, and nested functions can have names.

Function body could be a block statement (within '{' and '}'), or a single line expression after '=>'.

Return type is marked by a single arrow ('->') after the parameters brackets.

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

Function are first class in Hetu script, you can pass them as arguments, return value and store/rebind them to variables.

### Variadic parameter

In function declaration's parameters. '...' means you can pass as many positional arguments as you wish.

```javascript
external fun print(... args: any)

print('hello', 'world!', 42) // okay!
```

### Return value

If there's a return statement is the function body, it will return the value of the expression after the keyword.

If there's no return type declaration nor return statement in the actual function body. Functions will inexplicitly return the last expression's value as its return value.

### Literal function (sometimes called function expression, anonymous function or lambda)

```javascript
fun closure(func) {
  var i = 42
  fun nested () {
    i = i + 1
    print(func(i))
  }
  return nested
}

var func = closure( (n) => n * n )
func()
```

A literal function can have no keyword, in this situation, the parameter brackets are not omittable even if it's empty. The following way to define a function is all okay and they are the same to the compiler.

```dart
final func1 = fun { return 42 }
final func2 = fun => 42
final func3 = () { 42 }
final func4 = () => 42
```

## Class

Class can have static variables and methods. Which can be accessed through the class name.

Class's member functions use special keyword: **construct, get, set**, to define a constructor, getter, setter function.

Constructors can be with no function name and cannot return values. When calling they will always return a instance.

Getter & setter functions is used like a member variable. They can be accessed without brackets.

Use 'extends' to inherit other class's members

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
    // when there's no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

## Struct

Struct are a prototype base object system. This is mainly borrowed from Javascript.

### Named struct

Named struct's declaration are like class, you can have constructors, getter and setters.

You don't have to declare the fields before assign it like you must do in Class declarations. This is useful for constructor.

```javascript
struct Named {
  construct (name: str) {
    this.name = name
  }
}
```

The named struct declaration itself is also a struct. you can access and modify its member.

However this kind of modification won't affect the object that created before.

```dart
final n = Named('Jimmy')
Named.name = 'Jones'
print(n.name) // 'Jimmy'
```

You can define static fields on a named struct.

Unlike class static members, the object created by the struct constructor can also access these fields through '.' operator.

And if you changed the static fields in a named struct. All the object created from this named struct, nomatter it was created before or after the change, will be getting the new value.

```javascript
struct Named {
  static var race = 'Human'
  var name
  construct(name) {
    this.name = name
  }
}
final n = Named('Jimmy')
print(n.name) // Jimmy
print(Named.name) // null
Named.race = 'Dragon'
print(n.race) // Dragon
```

One important thing worth noted: within a named struct's method, **you cannot omit 'this' when accessing its own members** like you would do in a class method.

### Struct inherit

Named struct can declare its prototype same way as a class.

```javascript
struct Animal {
  walk: () {
    print('Animal walking.')
  }
}
struct Bird extends Animal {
  fly: () {
    print('Bird flying.')
  }
  walk: () {
    print('Bird walking.')
  }
}
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

Struct's prototype can be accessed and modified through '$prototype'.
Struct's root prototype has two functions: toString() and toJson(). Can be used to easily convert a struct into other code.

### Literal struct and literal function

You can bind a literal function (and only a literal function) onto a literal struct object and get a new function.

This is useful when you want to seperate data and logic, and still want the function to be able to have 'this' keyword.

Notice that this method won't modify the function itself. It will give you a new function instead.

```dart
final obj = {
  name: 'nobody'
}
final func = () {
  this.name = 'foobar'
}
final newfunc =func.bind(obj)
newfunc()
print(obj.name) // 'foobar'
```

### Delete a struct member

It is possible to delete a struct field using 'delete' keyword.

```javascript
var a = {
  name: 'the world',
  meaning: 42,
};
delete a.meaning;
print(a); // { name: 'the world' }
```

## Identifier

Identifiers are the names of classes, functions, types, members and fields. In common situations, you can only use letters or characters from any language, plus underscore and dollor sign.

You can define a identifier with a pair grave accent mark, then you can use any possible characters within it.

```dart
var obj = {
  `name-#42🍎`: 'aleph' // it's legal for a field name.
}

print(obj.`name-#42🍎`) // 'aleph'
```

## Namespace

You can create a code block within a source or a function body, by declaring with keyword **namespace** and an Identifer as its name.

The namespace code block works like a class definition. It only allows for variable/class/function declaration, but not for expresssions.

```c++
namespace universe {
  var meaning = 42
}

print(universe.meaning)
```

Refer [Do statement](#do) for another kind of code block.

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

### Truth value

If the interpreter is in non strict mode, the if/do/while statement's condition expression will be inexplicitly converted to boolean.

The conversion rules is:

```dart
/// inexpicit type conversion for truthy values
bool _truthy(dynamic condition) {
  if (_isStrictMode || condition is bool) {
    return condition;
  } else if (condition == null ||
      condition == 0 ||
      condition == '' ||
      condition == '0' ||
      condition == 'false' ||
      (condition is Iterable && condition.isEmpty) ||
      (condition is Map && condition.isEmpty) ||
      (condition is HTStruct && condition.fields.isEmpty)) {
    return false;
  } else {
    return true;
  }
}
```

### If

'if' statement's branches could be a single statement without brackets.
'if' can also be an expression which will have a value, in this case else branch is not omitable.

```javascript
if (condition) {
  ...
} else {
  ...
}
```

### Loop

#### While

```javascript
while (condition) {
  ...
}
```

#### Do

```javascript
do {
  ...
} while (condition)
```

'do' statement's 'while' part is optional, if omitted, it will become a anonymous code block. It's kind of like an anonymous function that immediately calls.

### For

'for' statement's expr must be separated with ';'.

The expression itself is optional. If you write 'for ( ; ; )', it will be the same to 'while (true)'

When use for...in, the loop will iterate through the keys of a list.

When use for...of, the loop will iterate through the values of a struct literal/Dart Map.

```dart
for (init; condition; increment) {
  ...
}

for (var item in list) {
  ...
}

for (var item of obj) {
  ...
}
```

### When

When is the substitue for 'switch' in older programming languages, we change its name to indicate more complex usages.

'when' statement's condition is optional. If not provided, the interpreter will check the cases and jump to the first branch if the expression evaled as true. In this case, the when statement is more like a if else statement except with a little more efficiency because it won't go through every branch.

'when' statement's case could be non-const expression or variables;

'when' statement's body must be enclosed in curly brackets. However, the case branch could be a single statement without brackets;

'when' statement's else branch is optional.

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
var job = 'wood cutter';
var person = {
  ...name,
  age: 23,
};
// same to:
// {
//   familyName: 'Hord',
//   firstName: 'Luk',
//   age: 23,
//   job: 'wood cutter'
// }
```

## Keywords

**null, true, false, void<sup>1</sup>, type<sup>1</sup>, import<sup>1</sup>, export<sup>1</sup>, from<sup>1</sup>, any<sup>1</sup>, unknown<sup>12</sup>, never<sup>12</sup>, var, final, const, def<sup>2</sup>, delete<sup>2</sup>, typeof, namespace, class, enum, fun, struct, this, super, abstract, override<sup>2</sup>, external, static, extends, implements<sup>2</sup>, with<sup>2</sup>, construct, factory, get, set, async<sup>2</sup>, await<sup>2</sup>, break, continue, return, for, in, of<sup>1</sup>, if, else, while, do, when, is, as**

1: These keywords are contextual. they only used in specific places, hence can be used as normal identifiers (class members, etc.).

2: These keywords have no really effect for now, they are reserved for future development.

## Operator precedence

| Description    | Operator                       | Associativity | Precedence |
| :------------- | :----------------------------- | :-----------: | :--------: |
| Unary postfix  | e., e?., e++, e--, e1[e2], e() |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e               |     None      |     15     |
| Multiplicative | \*, /, ~/, %                   |     Left      |     14     |
| Additive       | +,                             |     Left      |     13     |
| Relational     | <, >, <=, >=, as, is, is!      |     None      |     8      |
| Equality       | ==, !=                         |     None      |     7      |
| Logical AND    | &&                             |     Left      |     6      |
| Logical Or     | \|\|                           |     Left      |     5      |
| If null        | \?\?                           |     Left      |     4      |
| Conditional    | e1 ? e2 : e3                   |     Right     |     3      |
| Assignment     | =, \*=, /=, ~/=, +=, -=, ??=   |     Right     |     1      |
