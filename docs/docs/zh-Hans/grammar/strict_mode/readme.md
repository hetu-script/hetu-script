# 严格模式

可以通过修改 Hetu 解释器对象上的 strictMode 属性来指定以严格模式或者非严格模式进行解释。

```dart
final hetu = Hetu()..strictMode = true;
```

## 空值和零

在非严格模式下，null 可以被隐式转换为 0：

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## 布尔值

在非严格模式下，下列表达式的值可以被隐式转换为布尔值。

1, if (expr)

2, (expr) ? //... : //...

2, do { //... } while (expr)

3, while (expr)

4, expr1 && expr2

5, expr1 || expr2

布尔值隐式转换的规则如下：

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

**除了上述情况之外，其他场合并不会进行隐式类型转换。**
