# 结构体对象（struct）

河图中的结构体对象等同于 Javascript 中的对象。是一种以原型继承为基础，可以更自由的访问和创建对象成员的面向对象模式。

结构体对象的最大特点是，访问和修改不存在的成员，将会创造新成员。

```javascript
final obj = {}
obj.race = 'dragon' // okay, this will define a new member on obj.
var lvl = obj.level // okay, although lvl's value will be null
```

## 动态删除结构体的成员

使用 delete 关键字可以删除一个结构体对象上的成员。

```javascript
var a = {
  name: "the world",
  meaning: 42,
};
delete a.meaning;
print(a); // { name: 'the world' }
```

## 结构体对象字面量

结构体对象字面量本身是一个表达式，以 '{key: value}' 的形式定义。

```javascript
var obj = {
  name: 'jimmy'
  age: 17
}
```

对象字面量的 key 必须是一个合法的标识符，或者是一个字符串（不能使用字符串插值）。

## 命名结构体（named struct）

命名结构体的声明方式类似 class。可以包含 cosntruct/get/set 等 class 特有的方法关键字。也可以在构造函数声明中重定向到其他构造函数或者父类构造函数（通过 this 和 super），以及在构造函数的参数列表中使用 `this` 来快速初始化实例成员。

在命名结构体的构造函数中，可以通过 this 关键字，省略掉成员声明，而直接给一个不存在的成员赋值。

```javascript
struct Named {
  constructor (this.name) {} // 需要保留空括号作为函数体
}
```

访问命名结构体的标识符，也可以得到一个对象字面量，你也可以直接修改它的成员。

但这种形式的修改，不会影响到之前通过构造函数创造的对象。

```dart
final n = Named('Jimmy')
Named.name = 'Jones'
print(n.name) // 'Jimmy'
```

在命名结构体中，也可以定义一个静态（static）变量。在类（class）中定义的静态变量，只能通过 '类名.静态成员名' 的方式访问。但命名结构体中的静态变量是可以通过 '对象名.静态成员名' 的方式访问的。

并且，如果你修改了这个静态成员的值，所有从这个命名结构体的构造函数获得的结构体对象，都可以访问到修改后的新值。

```javascript
struct Named {
  static var race = 'Human'
  var name
  constructor(name) {
    this.name = name
  }
}
final n = Named('Jimmy')
print(n.name) // Jimmy
print(Named.name) // null
Named.race = 'Dragon'
print(n.race) // Dragon
```

另外一点要注意的是，命名结构体的函数在任何时候都必须通过 **this** 才能访问到这个结构体对象的成员。这一点和类不同。

### 命名结构体的继承

命名结构体可以声明继承的对象。本质上就是指定这个结构体的原型对象。继承可以是任何结构体对象。并不一定要求是另一个命名结构体。

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

命名结构体也可以像类那样在命名构造函数之后使用 **this** 关键字转移到默认构造函数上去（但不能使用 **super** 关键字）。

```javascript
struct Tile {
  constructor (left, top) {
    this.left = left
    this.top = top
  }

  constructor fromPosition(position) : this(position.left, position.top)
}

final t1 = Tile(5, 5)
final t2 = Tile.fromPosition({left: 5, top: 5})

print(t1, t2)
```

你可以在结构体字面量之前使用 struct 关键字（正如你也可以在一个函数字面量之前使用 function 关键字）。

这种写法可以更方便的直接指定一个结构体的原型。

```dart
struct P {
  var name = 'guy'
  var age = 17
}

final p1 = struct extends P {}
```

或者，你也可以通过内部成员 **$prototype** 动态的修改一个结构体的原型。。

```dart
final p2 = {}
p2.$prototype = P
```

### 命名结构体混入其他结构体

当使用 extends 来继承时，结构体会将继承对象放在 $prototype 变量内。因此尽管在运行时可以访问到父类成员，但在打印时或 toJson 时，不会输出父类的成员。

如果希望直接在声明时就将另一个结构体的内容拷贝并混入当前结构体，可以使用关键字 with 取代 extends。

```javascript
struct Winged {
  function fly {
    print('i\'m flying')
  }
}

struct Person with Wings {

}

final p = Person()
p.fly()
```
