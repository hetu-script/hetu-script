# Type declaration

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
