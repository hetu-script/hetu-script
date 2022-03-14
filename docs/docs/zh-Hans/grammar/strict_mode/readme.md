# 严格模式

可以通过修改 Hetu 解释器对象上的 config 属性来指定以某些非严格模式进行解释。

```dart
var hetu = Hetu(
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

## 变量名覆盖

当 config.allowVariableShadowing == true 时，你可以在同一个函数的命名空间中声明一个相同名字的变量，来覆盖之前的声明。

这个选项默认是打开的。

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## 隐式变量定义

当 config.allowImplicitVariableDeclaration == true 时，对不存在的标识符赋值，将会自动创建新的变量：

```javascript
a = 42; // a is created!.
```

## 空值和零

当 config.allowImplicitNullToZeroConversion == true 时，null 可以被隐式转换为 0：

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## 布尔值

当 config.allowImplicitEmptyValueToFalseConversion == true 时，下列表达式的值，如果为人类主观意义上的空值（包括 0，空字符串等等）可以被隐式转换为布尔值。

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

**除了上述情况之外，其他场合并不会进行隐式类型转换。**
