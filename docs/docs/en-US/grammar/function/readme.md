# Function

Function is declared with **function**, **get**, **set**, **constructor**. The parameter list, return type and function body are all optional. For functions with no parameters, the empty brackets are also optional.

For a literal function expression, the function name is also optional if there's no type arguments and dart function typedef.

```typescript
function doubleIt(n: num) -> num {
  return n * 2
}

function main {
  var x = doubleIt(7) // expect 14
  print(x)
}
```

For functions with no return type provided in declaration, it will have a return type of **any**. And it will return the last expression's value if you didn't write return statement within the definition body.

Functions can be nested, and nested functions can have names.

Return type is marked by a single arrow ('->') after the parameters brackets.

```typescript
function closure(func) {
  var i = 42
  function nested {
    i = i + 1
    return(func(i))
  }
  return nested
}

function main {
  var func = closure( (n) => n * n )
  print(func()) // print: 1849
  print(func()) // print: 1936
}
```

Function are first class in Hetu script, you can pass them as arguments, return value and store/rebind them to variables.

## Single line function body

Just like in Dart, you can write a single line expression after '=>' as function body.

```dart
var func = (x) => x * x
final sq = func(4) // sq = 16
```

## Optional parameter

You can use positional parameter or named parameter in your parameter declarations, and you can give them default values.

```javascript
function posParam(a, [b = 7]) {
  return a * b
}

final r1 = posParam(6) // r1 = 42

function namedParam({a = 3, b = 9}) {
  return a * b
}

final r2 = namedParam(b: 10) // r2 = 30
```

## Variadic parameter

In function declaration's parameters. '...' means you can pass as many positional arguments as you wish.

```javascript
external function print(... args: any)

print('hello', 'world!', 42) // okay!
```

## Omit parameter

In function declaration's parameters. '\_' means you won't use this positional parameter in this implementation of a function type. This is useful in functional programming.

```javascript
function test1(expect, value, [arg]) {
  print("running test1 with ${arg}: expect ${expect}, value ${value}");
}

function test2(_, value, [_]) {
  print(value);
}

function run(expect, value) {
  test1(expect, value, "test1");
  test2(expect, value, "test2");
}
```

## Return value

If there's a return statement is the function body, it will return the value of the expression after the keyword.

If there's no return type declaration nor return statement in the actual function body. Functions will inexplicitly return the last expression's value as its return value.

## Literal function (sometimes called function expression, anonymous function, closure or lambda)

```javascript
function closure(func) {
  var i = 42;
  function nested() {
    i = i + 1;
    print(func(i));
  }
  return nested;
}

var func = closure((n) => n * n);
func();
```

A literal function can have no keyword, in this situation, the parameter brackets are not omittable even if it's empty. The following way to define a function is all okay and they are the same to the compiler.

```dart
final func0 = function meaning { return 42 }
final func1 = function { return 42 }
final func2 = function => 42
final func3 = () { 42 }
final func4 = () => 42
```

## Immediately run literal function

Literal function is an expression, hence it has value, so just like in Javascript, you can immediately call it after the definition:

```javascript
() {
  return Future( () => 42 )
} ().then(
  (value){
    print(value)
  }
)
print(41)
```

The above output should be 41 then 42, because although the 42 is print in the first call, it happens later because it is wrapped in a future.

## Bind a literal function to a struct

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

## Apply a literal function to a struct

You can apply a literal function (and only a literal function) onto a literal struct object and get the function call result, as if the function is the member of that object.

Apply is a one time action and will neither modify the function nor generate a new one.

```dart
final obj = {
  name: 'nobody'
}
final greeting = () {
  print('Hi! I\'m ${this.name}')
}
greeting.apply(obj)
```
