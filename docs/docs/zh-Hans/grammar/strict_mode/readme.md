# 严格模式

可以通过修改 Hetu 解释器对象上的 config 属性来指定以某些非严格模式进行解释。

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

## 变量名覆盖

当 config.allowVariableShadowing == true 时，你可以在同一个函数的命名空间中声明一个相同名字的变量，来覆盖之前的声明。

这个选项默认是打开的。

```dart
var a = 42
var a = 'yay!' /// not an error, this is another variable
```

## 隐式变量定义

如果允许隐式变量定义，可以写出一些较为简洁，但有时候会令人难以看懂的代码。河图本身并不鼓励这种代码风格，但使用者可以通过 config 上的开关主动使用这种风格。在这种风格下，对不存在的标识符赋值，将会自动创建新的变量：

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

## 空值和零

当 config.allowImplicitNullToZeroConversion == true 时，null 可以被隐式转换为 0：

```javascript
final obj = {}
++obj.count // obj = { count: 1 }
```

## 布尔值

当 config.allowImplicitEmptyValueToFalseConversion == true 时，下列表达式的值，如果为人类主观意义上的空值（包括空字符串等等，但不包括 0）可以被隐式转换为布尔值。

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

**除了上述情况之外，其他场合并不会进行隐式类型转换。**
