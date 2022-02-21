# Type system

**WARNING: Type system is not fully implemented yet. It's more of a kind of annotation. You won't get analysis errors from them currently.**

## Type as a value

Type is a top class value in Hetu, it can be assigned and returned.

You can assign a type value to a name with **type** declaration.

And you can get a type value after **is** keyword.

In other situations, you cannot use type values within expressions.

## Type declaration

Type declaration is similar to a variable declaration, except it used keyword **type** and must has a initializer type expression.

```typescript
class Person {}

type PType = Person
type funcTypedef = fun(str) -> num
type structTypedef = {
  name: str,
  age: num,
}
```

## typeof

Use **typeof** keyword to dynamically get the runtime type of a value.

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

The type of a type is always 'type', no matter it's a primitive, instance, or function type.

```typescript
type functype = ()->any
print(typeof functype) // type
>>>
```
