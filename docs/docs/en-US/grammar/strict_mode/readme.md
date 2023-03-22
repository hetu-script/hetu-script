# Strict mode

You can set some flag on Hetu's config, to change some behavior regarding strict mode.

```dart
final hetu = Hetu(
  config: InterpreterConfig(
    allowVariableShadowing: true,
    allowImplicitVariableDeclaration: true,
    allowImplicitNullToZeroConversion: true,
    allowImplicitEmptyValueToFalseConversion: true,
  ),
);
```

## Variable shadowing

If config.allowVariableShadowing == true, you can define a variable with the same name of another variable in the same namespace without errors.

This config is default to true.

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## Implicit variable declaration

if implicit variable declaration is allowed, you can write some converse while somewhat confusing code.

Hetu doesn't encourage this style of coding by default, however you can turn on this style by the config.

```javascript
// new variable will be created when assigning to a non-exist id.
a = 42;

// you can omit the declaration keyword in for statement,
// if allowImplicitVariableDeclaration is true.
for (i in items) {
  print(i);
}

// you can create a variable in expression,
// and use it later.
if ((err = func())) {
  print(err);
}
```

## Zero value

If config.allowImplicitVariableDeclaration == true, null value will be treated as 0 in these situations: <, >, <=, >=, +, -, ++, --, _, /, ~/, %, +=, -=, _=, /=, ~/=, %=.

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

**In other situations null value won't be inexplicitly converted, for example == & !=.**.

## Truth value

If config.allowImplicitVariableDeclaration == true, some expressions (normally empty valus, but not include '0') will be inexplicitly converted to boolean:

1, if (expr)

2, (expr) ? //... : //...

2, do { //... } while (expr)

3, while (expr)

4, expr1 && expr2

5, expr1 || expr2

The conversion rules is:

```dart
/// inexpicit type conversion for truthy values
bool _truthy(dynamic condition) {
  if (config.allowImplicitEmptyValueToFalseConversion) {
    if (condition == false
        condition == null ||
        condition == '' ||
        condition == 'false' ||
        (condition is Iterable && condition.isEmpty) ||
        (condition is Map && condition.isEmpty) ||
        (condition is HTStruct && condition.isEmpty)) {
      return false;
    } else {
      return true;
    }
  } else {
    return condition;
  }
}
```

**In other situations boolean won't be inexplicitly converted**.
