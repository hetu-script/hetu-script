# Private members

You can specify a private member of a class/namespace/source by making its name starts with '\_'.

```dart
class Person {
  var _name
  construct (name) {
    _name = name
  }
  fun greeting {
    print('Hi, I\'m ', _name)
  }
}
final p = Person('jimmy')
// print(p._name) // Error!
p.greeting()
```
