# Strict mode

## Zero value

In non-strict mode, null can be treated as 0.

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## Truth value

In non-strict mode, the if/do/while statement's condition expression will be inexplicitly converted to boolean.

The conversion rules is:

```dart
/// inexpicit type conversion for truthy values
bool _truthy(dynamic condition) {
  if (_isStrictMode || condition is bool) {
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
