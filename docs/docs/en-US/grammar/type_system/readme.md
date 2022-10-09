# Type system

**WARNING: Type system is not fully implemented yet. It's more of a kind of annotation. You won't get analysis errors from them currently.**

## Type as a value

Type is a top class value in Hetu, it can be assigned and returned.

However, you cannot use type value in normal expressions except class names. Normally you have to either use a type declaration to bind a type value to a identifier. Or to get a type value expression after is/as keyword.

There are 4 kinds of type values:

### builtin type

Some types are builtin keyword and has special use:

#### any

This is the equivalent keyword to Dart's dynamic, to indicate that this type can be assign with anything.

**void, never & unknown are also builtin keyword, they are part of static type checker, and they are not fully implemented for now.**

### nominal type

All class names can be used in a type value expression.

```typescript
class Person {}
```

### structural type

Structural type are a kind of [duck typing system](https://en.wikipedia.org/wiki/Duck_typing). It is used with [struct](../struct/readme.md).

It's syntax like the struct literal, however, you have to write types rather than a expression value after the key:

```dart
typedef StructTypedef = {
  name: str,
  age: num,
};
```

### function type

Function types are a kind of type value expression that consists of a parameter type brackets and a return value.

Unlike normal function declarations, You cannot omit any part in the function type expression.

It should have a pair of brackets, a single arrow and a return type.

```dart
typedef FuncTypedef = (str) -> num
```

## Type declaration

You can assign a type value to a name with **typedef** declaration.

Type declaration is similar to a variable declaration, except it must has a initializer type expression.

```dart
class Person {}

typedef PType = Person
typedef FuncTypedef = (str) -> num
typedef StructTypedef = {
  name: str,
  age: num,
}
```

## Use is to check a type in run-time

Use **is** to do a run-time type check. The expression after **is** will be parsed into a valid type value.

```javascript
fun doSomething(value) {
  if (value is str) {
    print('A String!')
  } else if (value is num) {
    print('A Number!')
  } else {
    print('Unknown type!')
  }
}
```

## Use typeof to get a type in run-time

Use **typeof** keyword to dynamically get the runtime type of a value.

```dart
fun main {
  // decalre a function typedef
  typedef FuncTypedef = fun(str) -> num
  // assign a function to a value of a certain function type
  var numparse: FuncTypedef = fun(value: str) -> num { return num.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = fun { return typeof numparse }
  var FuncTypedef2 = getType()
  // use this new type
  var strlength: FuncTypedef2 = fun(value: str) -> num { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

The type of a type is always 'type', no matter it's a primitive, instance, or function type.

```dart
typedef Functype = () -> any
print(typeof functype) // type
```
