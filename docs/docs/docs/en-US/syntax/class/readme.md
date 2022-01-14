# Class

Class can have static variables and methods. Which can be accessed through the class name.

Class's member functions use special keyword: **construct, get, set**, to define a constructor, getter, setter function.

Constructors can be with no function name and cannot return values. When calling they will always return a instance.

Getter & setter functions is used like a member variable. They can be accessed without brackets.

Use 'extends' to inherit other class's members

```typescript
// class definition
class Calculator {
  // instance member
  var x: num
  var y: num
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
  // constructor with parameters
  construct (x: num, y: num) {
    // use this to access instance members with same names
    this.x = x
    this.y = y
  }
  // method with return type
  fun meaning -> num {
    // when there's no shadowing, `this` keyword can be omitted
    return x * y
  }
}
```

## Constructor tear off

Sometimes, we would like to use Class constructors in functional programming situations. However it normally doesn't work because if you directly pass a class name into a place where a function is needed, you won't get what you want: to call this class's name as a function and get a instance as its result.

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

You can create a code block within a source or a function body, by declaring with keyword **namespace** and an Identifer as its name.

This is equivalent to define a abstract class with only static members in Dart.

The namespace code block only allows for variable/class/function declaration, no import, export, expresssions allowed.

```c++
namespace universe {
  var meaning = 42
}

print(universe.meaning)
```

Refer [Do statement](../control_flow/readme.md#do) for another kind of code block.
