# Function

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

## Variadic parameter

In function declaration's parameters. '...' means you can pass as many positional arguments as you wish.

```javascript
external fun print(... args: any)

print('hello', 'world!', 42) // okay!
```

## Return value

If there's a return statement is the function body, it will return the value of the expression after the keyword.

If there's no return type declaration nor return statement in the actual function body. Functions will inexplicitly return the last expression's value as its return value.

## Literal function (sometimes called function expression, anonymous function, closure or lambda)

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
