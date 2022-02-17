# 结构体（struct）

河图中的结构体等同于 Javascript 中的对象字面量。是一种以原型继承为基础，可以更自由的访问和创建对象成员的面向对象模式。

## 命名结构体（named struct）

命名结构体的声明方式类似 class。可以包含 cosntruct/get/set 等 class 特有的方法关键字。

在命名结构体的构造函数中，可以通过 this 关键字，省略掉成员声明，而直接给一个不存在的成员赋值。

```javascript
struct Named {
  construct (name: str) {
    this.name = name
  }
}
```

访问命名结构体的标识符，可以得到一个对象字面量，你也可以直接修改它的成员。

但这种形式的修改，不会影响到之前通过构造函数创造的对象。

```dart
final n = Named('Jimmy')
Named.name = 'Jones'
print(n.name) // 'Jimmy'
```

You can define static fields on a named struct.

Unlike class static members, the object created by the struct constructor can also access these fields through '.' operator.

And if you changed the static fields in a named struct. All the object created from this named struct, nomatter it was created before or after the change, will be getting the new value.

```javascript
struct Named {
  static var race = 'Human'
  var name
  construct(name) {
    this.name = name
  }
}
final n = Named('Jimmy')
print(n.name) // Jimmy
print(Named.name) // null
Named.race = 'Dragon'
print(n.race) // Dragon
```

One important thing worth noted: within a named struct's method, **you cannot omit 'this' when accessing its own members** like you would do in a class method.

## Struct inherit

Named struct can declare its prototype same way as a class.

```javascript
struct Animal {
  walk: () {
    print('Animal walking.')
  }
}
struct Bird extends Animal {
  fly: () {
    print('Bird flying.')
  }
  walk: () {
    print('Bird walking.')
  }
}
```

Redirecting constructors also works in struct. Except you cannot redirect to **super**, usage is same to class constructors.

```javascript
struct Tile {
  construct (left, top) {
    this.left = left
    this.top = top
  }

  construct fromPosition(position) : this(position.left, position.top)
}

final t1 = Tile(5, 5)
final t2 = Tile.fromPosition({left: 5, top: 5})

print(t1, t2)
```

## Literal struct

Literal struct are expressions in the form of '{key: value}'

```javascript
var obj = {
  name: 'jimmy'
  age: 17
}
```

The key must be either a identifier, or a string literal (not includes string interpolation).

Struct are different from class, that you wont get errors when you visit a non-exist member.

```javascript
obj.race = 'dragon'; // okay, this will define a new member on obj.
var lvl = obj.level; // okay, although lvl's value will be null
```

Struct's prototype can be accessed and modified through '$prototype'.
Struct's root prototype has two functions: toString() and toJson(). Can be used to easily convert a struct into other code.

## Delete a struct member

It is possible to delete a struct field using 'delete' keyword.

```javascript
var a = {
  name: 'the world',
  meaning: 42,
};
delete a.meaning;
print(a); // { name: 'the world' }
```
