# Strict mode

You can set some flag on Hetu's config, to change some behavior regarding strict mode.

```dart
final hetu = Hetu(
  config: InterpreterConfig(
    checkTypeErrors: true,
    computeConstantExpressionValue: true,
    allowVariableShadowing: true,
    allowImplicitVariableDeclaration: true,
    allowImplicitNullToZeroConversion: true,
    allowImplicitEmptyValueToFalseConversion: true,
  ),
);
```

## Variable shadowing

If config.allowVariableShadowing == true, youcan define a variable with the same name of another variable in the same namespace without errors.

This config is default to true.

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## Implicit variable declaration

If config.allowImplicitVariableDeclaration == true, a new variable will be created when assigning to a non-exist id.

```javascript
a = 42; // a is created!.
```

## Zero value

If config.allowImplicitVariableDeclaration == true, variable with null value can be treated as 0.

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## Truth value

If config.allowImplicitVariableDeclaration == true, some expressions will be inexplicitly converted to boolean:

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
    if (condition == null ||
        condition == 0 ||
        condition == '' ||
        condition == '0' ||
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
