# Type system

The Hetu type system supports four kinds of types at runtime: builtin types, nominal types (class names), structural types (duck typing), and function types. Runtime type checks via `is`, `is!`, `as`, `typeof`, and `decltypeof` are fully supported. Static type analysis is available separately by enabling `doStaticAnalysis` in the Hetu config — the analyzer is under active development.

## Type as a value

Type is a top class value in Hetu, it can be assigned and returned.

To use a type value in a normal expression, you have to lead it with a `type` keyword.

```typescript
function checkType(t: type) {
  switch (t) {
    typeval {} : {
      print('a structural type')
    }
    // the function won't match here
    // you have to use the exact type value here for match
    typeval ()->any : {
      print('a function type')
    }
  }
}
```

## Type declaration

You can assign a type value to a name with **type** declaration.

Type declaration is similar to a variable declaration, except it must has a initializer type expression.

```typescript
class Person {}

type PType = Person
type FuncTypedef = (string) -> number
type StructTypedef = {
  name: string,
  age: number,
}
```

There are 4 kinds of type values:

### builtin type

Some types are builtin keyword and has special use:

#### any

This is the equivalent keyword to Dart's dynamic, to indicate that this type can be assign with anything.

**void, never & unknown are also builtin keyword. `void` represents the absence of a return value. `never` is the bottom type (a subtype of all types). `unknown` is the top type for unanalyzed code. These are primarily used during static type checking, but are valid type values at runtime.**

### nominal type

All class names can be used in a type value expression.

```typescript
class Person {}
```

### structural type

Structural type are a kind of [duck typing system](https://en.wikipedia.org/wiki/Duck_typing). It is used with [struct](../struct/readme.md).

It's syntax like the struct literal, however, you have to write types rather than a expression value after the key:

```typescript
type StructTypedef = {
  name: string;
  age: number;
};
```

### function type

Function types are a kind of type value expression that consists of a parameter type brackets and a return value.

Unlike normal function declarations, You cannot omit any part in the function type expression.

It should have a pair of brackets, a single arrow and a return type.

```typescript
type FuncTypedef = (string) -> number
```

## Use is / is! to check a type in run-time

Use **is** to do a run-time type check. The expression after **is** will be parsed into a valid type value, and you don't need to use `type` keyword after `is`.

Use **is!** to check that a value is NOT of a given type.

```typescript
function doSomething(value) {
  if (value is string) {
    print('A String!')
  } else if (value is number) {
    print('A Number!')
  } else if (value is! bool) {
    print('Not a Boolean!')
  } else {
    print('Unknown type!')
  }
}
```

## Use as for type casting

Use **as** to cast a value to a specific type at runtime. If the cast is invalid (the value is not of the target type), a runtime error is thrown.

```typescript
class Super3 {
  var name = 'Super'
}
class Extend3 extends Super3 {
  var name = 'Extend'
}
var a = Extend3()
var b = a as Super3
print(b.name) // 'Extend' — b still refers to the same Extend3 instance
```

## Use typeof to get a type in run-time

Use **typeof** keyword to dynamically get the runtime type of a value.

```typescript
function main {
  // decalre a function type
  type FuncTypedef = function(string) -> number
  // assign a function to a value of a certain function type
  var numparse: FuncTypedef = function(value: string) -> number { return number.parse(value) }
  // get a value's runtime type and return it from a function
  var getType = function { return typeof numparse }
  var FuncTypedef2 = getType()
  // use this new type
  var strlength: FuncTypedef2 = function(value: string) -> number { return value.length }
  // expected output: 11
  print(strlength('hello world'))
}
```

The type of a type is always 'type', no matter it's a primitive, instance, or function type.

```typescript
type Functype = () -> any
print(typeof functype) // type
```

## Use decltypeof to get a declared type

Use **decltypeof** keyword to get the declared type annotation of a variable, rather than the runtime type of its current value. This is useful for inspecting type annotations at runtime.

```typescript
class Person {}
var p: Person = Person()
print(decltypeof p) // Person (the declared type)
print(typeof p)     // Person (the runtime type — same in this case)
```
