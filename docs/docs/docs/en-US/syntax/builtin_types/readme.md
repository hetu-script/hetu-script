# Primitive (buildin) types and classes

- null
- bool
- int
- float (i.e. double is Dart)
- String
- List\<dynamic\>
- Set\<dynamic\>
- Map\<dynamic, dynamic\>
- Function

There's no literal syntax for Set & Map, you have to create them by using constructors.

## Big integers

The builtin integers in script are int32, which range from -2,147,483,648 to 2,147,483,647. This is due to the limitation of the runtime.js of Dart.

To manipulate bigger numbers, you can use preincluded class BigInt.

```dart
final bi = BigInt.parse("9223372036854775807")
```
