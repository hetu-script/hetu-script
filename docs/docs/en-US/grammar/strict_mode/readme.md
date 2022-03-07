# Strict mode

You can set the strict mode flag on Hetu. Its default value is false.

```dart
final hetu = Hetu()..strictMode = true;
```

## Zero value

In non-strict mode, variable with null value can be treated as 0.

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## Truth value

In non-strict mode, some expressions will be inexplicitly converted to boolean:

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
  if (strictMode || condition is bool) {
    return condition;
  } else if (condition == null ||
      condition == 0 ||
      condition == '' ||
      condition == '0' ||
      condition == 'false' ||
      (condition is Iterable && condition.isEmpty) ||
      (condition is Map && condition.isEmpty) ||
      (condition is HTStruct && condition.fields.isEmpty)) {
    return false;
  } else {
    return true;
  }
}
```

**In other situations boolean won't be inexplicitly converted**.
