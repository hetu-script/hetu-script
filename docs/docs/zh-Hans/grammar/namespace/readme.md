# 命名空间

命名空间（namespace）提供了一种将相关声明分组并控制可见性的方式。可以在模块顶层使用，也可以嵌套在类内部。

## 语法

```dart
namespace MyNamespace {
  var value = 42

  function sayHello() {
    print('Hello from MyNamespace!')
  }

  class Inner {
    var name = 'inner'
  }
}

// 使用 :: 访问命名空间成员
print(MyNamespace::value)       // 42
MyNamespace::sayHello()          // Hello from MyNamespace!
```

使用 `::`（双冒号）运算符从外部访问命名空间成员。在命名空间内部，成员可以直接通过名称访问。

## 私有成员

名称以 `_`（下划线）开头的成员对命名空间是私有的，不能从外部访问：

```dart
namespace Secret {
  var _internalCounter = 0

  function increment() {
    _internalCounter++
  }
}

print(Secret::increment)  // OK
print(Secret::_internalCounter)  // Error: 私有成员
```

## 嵌套命名空间

命名空间可以嵌套：

```dart
namespace Outer {
  namespace Inner {
    function deep() {
      return 42
    }
  }
}

print(Outer::Inner::deep())  // 42
```

## 命名空间与类

类体隐式形成一个命名空间。静态成员通过类的命名空间访问：

```dart
class Math {
  static var PI = 3.14159
  static function square(x) { return x * x }
}

print(Math::PI)       // 3.14159
print(Math::square(3)) // 9
```

## 导入中的命名空间

导入模块时，可以将其别名化为命名空间前缀：

```dart
import 'some_library.ht' as lib
lib::someFunction()
```

## 命名空间中的外部函数

绑定到特定命名空间的外部函数可以使用 `Namespace::functionName` 命名约定注册：

```dart
hetu.bindExternalFunction('MyNamespace::myFunc', (List<dynamic> args) {
  // ...
});
```
