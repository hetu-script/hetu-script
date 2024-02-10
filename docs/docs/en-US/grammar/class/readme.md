# Class

Class can have static variables and methods. Which can be accessed through the class name.

Member functions can also be declared with **get**, **set**, **constructor**, they means getter, setter and contructor function.

If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty parentheses.

Constructors can be with no function name and cannot return values. When calling they will always return a instance.

You can use `this` syntax in the parameter to quick initialize the member on instance just like in Dart.

```typescript
// class definition
class Calculator {
  // static private member
  static var _name = 'the calculator'
  // static get function
  static get name -> str {
    return _name
  }
  // static set function
  static set name(new_name: str) {
    _name = new_name
  }
  // static function
  static function greeting {
    print('hello! I\'m ' + name)
  }

  // instance member
  var x: num
  var y: num

  var birthDate
  // constructor with parameters
  // you can use `this` syntax in the parameter to
  // quick initialize the member on instance
  // just like in Dart
  constructor (this.x: num, this.y: num, age: int) {
    // use this to access instance members shadowed by function parameters
    this.birthDate = Now() + age
  }
  function meaning -> num {
    // when there's no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

## Inheritance

Use 'extends' to inherit other class's members.

```typescript
class Animal {
  function walk {
    print('animal walking')
  }

  var kind

  constructor (kind) {
    this.kind = kind
  }
}

class Bird extends Animal {
  function animalWalk {
    // You can access a overrided member in super class by the super keyword within a method body.
    super.walk()
  }
  // override super class's member
  function walk {
    print('bird walking')
  }
  function fly {
    print('bird flying')
  }

  // You can use super class's constructor by the super keyword after a constructor declaration.
  constructor _: super('bird')

  // factory is a special kind of contructor that returns values.
  // factory are static and cannot directly access instance members and constructors.
  factory {
    return Bird._()
  }
}
```

## super

Within a instance's namespace, use **super** to access the super class's members.

```dart
class Super3 {
  var name = 'Super'
}
class Extend3 extends Super3 {
  var name = 'Extend'
  function getSuperName() {
    return super.name
  }
}
```

You cannot use super in static methods.

## Type conversion

Outside a class's namespace, use **as** to convert a sub class to any super class it extends from.

You can then access that specific class's members.

```dart
class Super3 {
  var name = 'Super'
}
class Extend3 extends Super3 {
  var name = 'Extend'
}
var a = Extend3()
var b = a as Super3
b.name = 'Changed'
print((a as Super3).name) // 'Changed'
```

## Constructor tear off

Sometimes, we would like to use Class constructors in functional programming situations. However it normally doesn't work because a class name resolves into a 'class' or 'type' object rather than a function which is needed.

However, we can achieve this by accessing the internal name of the constructor(**$constructor**):

```javascript
class Person {
  var name
  constructor (name) {
    this.name = name
  }
}

final ctor = Person.$constructor
final p = ['jimmy', 'wang', 'naruto']
final objectList = p.map((element) {ctor(element)})
```

## Namespace

It's common in Dart to define a abstract class with only static members for restricting some values or methods to a namespace.

In Hetu script, you can directly create a code block with keyword **namespace** to achieve this.

The namespace code block only allows for variable/class/function declaration, cannot have import statement or expresssions.

```c++
namespace universe {
  var meaning = 42
}

print(universe.meaning)
```

Refer [Do statement](../control_flow/readme.md#do) for another kind of code block.
