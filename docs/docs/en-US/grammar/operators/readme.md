# Syntax and operators

## Spread syntax

You can use spread syntax ('...') in three places:

### Function call argument

In function call's arguments. This means to 'spread' the list object here to fill in the positional argument list.

```javascript
function someFunc(a, b) {
  print(a + b);
}
var list = [5, 6];
someFunc(...list); // same to 'someFunc(5, 6)'
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
  familyName: "Hord",
  firstName: "Luk",
};
var job = "wood cutter";
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

## Null check syntax

The script is not planning to introduce null safety. However, there are some syntax to help do null check:

```dart
var a // a is null
// Nullable member get:
final value = a?.value // value is null and we won't get errors
final result = a?() // nullabla function call
// If null then get another value
final text = a ?? 'hi!' // text is 'hi!'
// If null then assign
a ??= 42
print(a) // a is 42 now
```

The nullable check will pass to next unary postfix operator like a chain:

```dart
var a // a is null
final value = a?.collection[0].value() // value is null and we won't get errors
```

## new

new is a explicit way to call a constructor. Its difference from normal function call is that you can omit the brackets if there's none arguments.

```dart
struct P {
  var name = 'Jimmy'
}
final p = new P
print(p)
```

## Operator precedence

Operators in Hetu is a subset of Dart:

| Description    | Operator                           | Associativity | Precedence |
| :------------- | :--------------------------------- | :-----------: | :--------: |
| Unary postfix  | e., e?., e++, e--, e1[e2], e()     |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e, await e          |     None      |     15     |
| Multiplicative | \*, /, ~/, %                       |     Left      |     14     |
| Additive       | +,                                 |     Left      |     13     |
| Relational     | <, >, <=, >=, as, is, is!, in, in! |     None      |     8      |
| Equality       | ==, !=                             |     None      |     7      |
| Logical AND    | &&                                 |     Left      |     6      |
| Logical Or     | \|\|                               |     Left      |     5      |
| If null        | \?\?                               |     Left      |     4      |
| Conditional    | e1 ? e2 : e3                       |     Right     |     3      |
| Assignment     | =, \*=, /=, ~/=, +=, -=, ??=       |     Right     |     1      |
