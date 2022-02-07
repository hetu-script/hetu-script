# Builtin types and classes

Most of the common primitive types in Hetu is in fact Dart values, you can use most of their apis directly and return them to Dart as it is.

- null
- bool
- num
- int
- double
- String
- List\<dynamic\>
- Set\<dynamic\>
- Map\<dynamic, dynamic\>
- Function (the Dart function object)

Note:

1, The type name for float numbers in Hetu is 'float'.
2, There's no literal syntax for Set & Map, you have to create them by using constructors.
3, All List\Set\Map created from the script side is of dynamic types.

## Big integers

Both of the literal form of float and integer numbers in script are stored as 32 byte sized, which range from -2,147,483,648 to 2,147,483,647 for int and . This is due to the limitation of the runtime.js of Dart.

To manipulate bigger numbers, you can use preincluded class BigInt.

```dart
final bi = BigInt.parse("9223372036854775807")
```

## Future

Check [this page](../future/readme.md).
