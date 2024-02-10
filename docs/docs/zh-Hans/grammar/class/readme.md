# 类（class）

河图中的类是类似 C++/Java/Dart 中的 class 的一种名义类型（nominal type）。支持大多数 Dart 中的 class 的功能，例如构造函数，属性（get/set），继承（extends），以及在构造函数声明中重定向到其他构造函数或者父类构造函数（通过 this 和 super），以及在构造函数的参数列表中使用 `this` 来快速初始化实例成员。

但 mixin 和 implements 用法暂时不支持。

类中的方法声明使用专门的关键字：constructor/get/set/factory 等等。

下面是一个完整的例子：

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

## 继承

河图中类的继承使用 **extends** 关键字：

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

在类的成员函数中可以使用 **super** 访问父类的成员

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

## 类型转换

使用 **as** 关键字可以将一个子类转换为任意一个父类，使用这种方式可以在类本身的命名空间之外访问父类成员，同时也可以访问到多个继承关系之上的某个类的成员。

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

## 函数式的构造函数

某些时候我们想要在某些函数式编程的场景使用构造函数，例如我们想要向数组的 map 方法传入一个构造函数。通常情况下这不可行。因为直接传递类名，得到的是一个类型，而不是构造函数本身。要实现这一点，在 Dart 中使用的是 [constructor tear-off](https://medium.com/dartlang/dart-2-15-7e7a598e508a#9c16) 的方法。

在河图中，可以通过内部关键字 **$constructor** 实现相同的用法：

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

## 命名空间

在 Java/Dart 中，经常会创建一个只包含静态成员的抽象类，来将一些函数或者常量限制到一个命名空间中。

在河图中，可以直接使用命名空间声明（namespace）实现相同的用法：

命名空间声明的语句块只能包含变量/类/函数声明，不能包含导入导出语句，以及表达式语句。

下面是一个例子：

```c++
namespace universe {
  var meaning = 42
}

print(universe.meaning)
```
