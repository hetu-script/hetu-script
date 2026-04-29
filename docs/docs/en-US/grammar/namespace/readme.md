# Namespace

Namespaces in Hetu provide a way to group related declarations and control visibility. They can be used at the top level of a module or nested within classes.

## Syntax

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

// Access namespace members with ::
print(MyNamespace::value)       // 42
MyNamespace::sayHello()          // Hello from MyNamespace!
```

The `::` (double colon) operator is used to access namespace members from outside. Within the namespace, members are accessed directly by name.

## Private members

Members whose names start with `_` (underscore) are private to the namespace and cannot be accessed from outside:

```dart
namespace Secret {
  var _internalCounter = 0

  function increment() {
    _internalCounter++
  }
}

print(Secret::increment)  // OK
print(Secret::_internalCounter)  // Error: private member
```

## Nested namespaces

Namespaces can be nested:

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

## Namespaces and classes

A class body implicitly forms a namespace. Static members are accessed through the class namespace:

```dart
class Math {
  static var PI = 3.14159
  static function square(x) { return x * x }
}

print(Math::PI)       // 3.14159
print(Math::square(3)) // 9
```

## Namespaces in imports

When importing a module, you can alias it to a namespace prefix:

```dart
import 'some_library.ht' as lib
lib::someFunction()
```

## External functions in namespaces

External functions bound to a namespace can be registered with the `Namespace::functionName` naming convention:

```dart
hetu.bindExternalFunction('MyNamespace::myFunc', (List<dynamic> args) {
  // ...
});
```
