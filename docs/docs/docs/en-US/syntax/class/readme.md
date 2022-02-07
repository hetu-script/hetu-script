# Class

Class can have static variables and methods. Which can be accessed through the class name.

Class's member functions use special keyword: **construct, get, set**, to define a constructor, getter, setter function.

Constructors can be with no function name and cannot return values. When calling they will always return a instance.

Getter & setter functions is used like a member variable. They can be accessed without brackets.

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
  static fun greeting {
    print('hello! I\'m ' + name)
  }

  // instance member
  var x: num
  var y: num
  // constructor with parameters
  construct (x: num, y: num) {
    // use this to access instance members shadowed by function parameters
    this.x = x
    this.y = y
  }
  fun meaning -> num {
    // when there's no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

## Inheritance

Use 'extends' to inherit other class's members.

```typescript
class Animal {
  fun walk {
    print('animal walking')
  }

  var kind

  construct (kind) {
    this.kind = kind
  }
}

class Bird extends Animal {
  fun animalWalk {
    // You can access a overrided member in super class by the super keyword within a method body.
    super.walk()
  }
  // override super class's member
  fun walk {
    print('bird walking')
  }
  fun fly {
    print('bird flying')
  }

  // You can use super class's constructor by the super keyword after a constructor declaration.
  construct _: super('bird')

  // factory is a special kind of contructor that returns values.
  // factory are static and cannot directly access instance members and constructors.
  factory {
    return Bird._()
  }
}
```

## Constructor tear off

Sometimes, we would like to use Class constructors in functional programming situations. However it normally doesn't work because a class name resolves into a 'class' or 'type' object rather than a function which is needed.

However, we can achieve this by accessing the internal name of the constructor(**$construct**):

```javascript
class Person {
  var name
  construct (name) {
    this.name = name
  }
}

final ctor = Person.$construct
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
