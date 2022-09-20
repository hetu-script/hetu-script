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

For instance, we can use the map api just like in Dart on an Iterable:

```dart
final result = range(10).map((value) => 'row: ${value}')
```

Note:

1, The type name for float numbers in Hetu is 'float'.

2, There's no literal syntax for Set & Map, you have to create them by using constructors.

3, All List\Set\Map created from the script side is of dynamic types.

## String

The type name for String in Hetu is 'str'.

### Interpolation

String literal can have interpolation the same to Javascript, you can use any expression within '${}':

```dart
var a = 'dragon'
// print: To kill the dragon, you have to wait 42 years.
print('To kill the ${a}, you have to wait ${6*7} years.')
```

Note it's different to Dart that you have to write a curly brackets even if you have only one identifier.

### Multiline

After version 0.4.0, string literal in Hetu support multiline, the syntax is same to normal string literal.

```dart
var p = 'PPP'
var m = 'MMM'
final s = '

${
  p
  +
  m
}'
print(s)
print('a
multiline
string
')
```

## Big integers

To manipulate bigger numbers, you can use preincluded class BigInt.

```dart
final bi = BigInt.parse("9223372036854775807")
```

## Future

Check [this page](../future/readme.md).
