# 和 Dart 代码的交互

在脚本中可以用三种方式和 Dart 代码进行交互：内置类，Json 和绑定。这三种方法各有优劣，可以根据实际需求选择。

## 和 Dart 传递值

你可以通过 **invoke()** 接口的参数来向脚本函数传递值。脚本会将这个函数的返回值直接返回到 Dart 这边。

```dart
final result = hetu.invoke('calculate', positionalArgs: [6, 7], namedArgs: {'isFloat': true};
// equivalent in script
// final result = calculate(6, 7, isFloat: true)
```

## 内置类

河图已经内置下面这些类的绑定，因此你可以直接在脚本中传递、修改这些对象：

- null
- bool
- int
- double (it is called float in the script)
- String
- List\<dynamic\>
- Set\<dynamic>
- Map\<dynamic, dynamic\>
- Function

你可以直接在脚本中使用 **[]** 语法来访问和修改 Dart 中的 **List, Map** 对象。也可以直接使用 **()** 来调用 Dart 中的函数。

## Json

脚本中的对象字面量，在 Dart 中体现为 **HTStruct** 对象。这个对象在 Dart 中可以像 Map 那样直接使用 **[]** 来修改其成员。在脚本中则具有 **toJson()** 和 **fromJson()** 接口。因此可以使用这个对象来在 Dart 和脚本之间传递数值。

例如我们在脚本中有如下定义：

```kotlin
fun main (data) {
  var book = prototype.fromJson(data)
  print(book)
}
```

在 Dart 代码中有如下定义：

```dart
final Map<String, dynamic> data = {
  'id': 324,
  'title': 'Catcher in the Rye',
}
hetu.invoke('main', positionalArgs: [data]);
```

我们将会在 Dart 中获得下面的输出结果：

```javascript
{
  id: 324,
  title: 'Catcher in the Rye',
}
```

## Binding

使用内置类和对象字面量来传递值比较简单快捷。但如果你想要使用 Dart 中的已有类定义，或者想要调用 Dart 函数，则需要通过绑定的方式。

### External function

你可以直接将任意 Dart 函数绑定到脚本中：

```dart
await hetu.init(externalFunctions: {
  'hello': () => {'greeting': 'hello'},
});
```

这样写比较简明易懂，但通过这种方式定义的外部函数绑定，将会使用 Dart 中的 **Function.apply** 功能调用，相比直接调用，这个功能的运行效率通常比较低下（大约慢 10 倍左右）。因此，建议以如下形式定义一个外部函数：

```dart
await hetu.init(externalFunctions: {
  'hello': (context, {positionalArgs, namedArgs, typeArgs}) => {'greeting': 'hello'},
});
```

包含类型的外部函数完整定义如下：

```dart
/// typedef of external function for binding.
typedef HTExternalFunction = dynamic Function(
    HTEntity entity,
    {List<dynamic> positionalArgs,
    Map<String, dynamic> namedArgs,
    List<HTType> typeArgs});
```

要使用你刚才定义的外部函数，需要在脚本中使用 **external** 关键字声明这个函数。

下面是一个绑定并使用外部函数的完整例子：

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) => {'greeting': 'Hello from Dart!'},
  });
  final hetuValue = hetu.eval(r'''
      external fun hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
```

上面的程序的输出结果是：

```
hetu value: {'greeting': 'Hello from Dart!', 'reply': 'Hi, this is Hetu.'}
```

### 绑定一个外部成员函数

你可以在脚本中的类定义中，定义外部函数

A Hetu class could have a external method, even if other part of this class is all Hetu.

When called, the first argument passed from the script will be the instance instead of the namespace.

For example, we have the following class with a external method:

```dart
class Someone {
  external fun calculate
}
```

We have to define a external method in Dart code:

```dart
dynamic calculate(object, {positionalArgs, namedArgs, typeArgs}) {
  // do somthing about the object
};
```

We have to bind this external method some where in the Dart code, before we can use it in Hetu:

```dart
// the key of this external method have to be in the form of 'className.methodName'
hetu.bindExternalFunction('Someone.calculate', calculate);
```

Then it's okay to call this in Hetu:

```dart
var ss = Someone()
ss.calculate()
```

You can also have a external method on a named struct:

```javascript
struct Person {
  external fun sing
}
```

Everything else you should do is the same to a external method on a class.

### External getter

For external getter, you don't need to have a external function or external method typed function. You can directly return the value in the dart code.

### 完整的绑定类的定义和声明

You can use a Dart object with full class definition in Hetu.

To achieve this, you have to write a full definition of that class in Hetu, which includes 4 parts of code:

- Original class definition of the class you intended to use in Hetu. For Dart & Flutter, this is the part where you already have when you import a library.
- An extension on that class. This part is used for dynamic reflection in Hetu and should return members of this class.
- A binding definition of that class, which extends **HTExternalClass** interface provided by Hetu's dart lib. This part is used for access to the constructor and static members of that class.
- A Hetu version of class definition of that class. This part is used for Hetu to understand the structure and type of this class.

You can check the following example for how to bind a class and its various kinds of members.

```dart
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  static final races = <String>['Caucasian'];
  static String _level = '0';
  static String get level => _level;
  static set level(value) => _level = value;
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  String name;
  String race;

  Person([this.name = 'Jimmy', this.race = 'Caucasian']);
  Person.withName(this.name, [this.race = 'Caucasian']);

  void greeting(String tag) {
    print('Hi! $tag');
  }
}

extension PersonBinding on Person {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'name':
        return name;
      case 'race':
        return race;
      case 'greeting':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            greeting(positionalArgs.first);
      case 'child':
        return child;
      default:
        throw HTError.undefined(varName);
    }
  }

  void htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'name':
        name = varValue;
        break;
      case 'race':
        race = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'Person':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person(positionalArgs[0], positionalArgs[1]);
      case 'Person.withName':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.withName(positionalArgs[0],
                (positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasion'));
      case 'Person.meaning':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.level':
        return Person.level;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    switch (varName) {
      case 'Person.race':
        throw HTError.immutable(varName);
      case 'Person.level':
        return Person.level = varValue;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as Person;
    return i.htFetch(varName);
  }

  @override
  void instanceMemberSet(dynamic object, String varName, dynamic varValue) {
    var i = object as Person;
    i.htAssign(varName, varValue);
  }
}

void main() {
  var hetu = Hetu();
  hetu.init(externalClasses: [PersonClassBinding()]);
  hetu.eval('''
      external class Person {
        var race: str
        construct([name: str = 'Jimmy', race: str = 'Caucasian']);
        get child
        static fun meaning(n: num)
        static get level
        static set level (value: str)
        construct withName(name: str, [race: str = 'Caucasian'])
        var name
        fun greeting(tag: str)
      }
      fun main {
        var p1: Person = Person()
        p1.greeting('jimmy')
        print(Person.meaning(42))
        print(typeof p1)
        print(p1.name)
        print(p1.child)
        print('My race is', p1.race)
        p1.race = 'Reptile'
        print('Oh no! My race turned into', p1.race)
        Person.level = '3'
        print(Person.level)

        var p2 = Person.withName('Jimmy')
        print(p2.name)
        p2.name = 'John'
      }
      ''', isModule: true, invokeFunc: 'main');
}
```

### Typedef of Dart function

It is possible to return a pure Dart function from the script side.

For example, in Hetu script, we have this function typedef:

```dart
fun [DartFunction] add(a: num, b: num) -> num {
  return a + b
}

fun getFunc {
  return add
}
```

Then when you evaluate this _add_ function in Hetu, you will get a native Dart function. This grammar could also be used on literal function, this is especially usefull when you try to bind callback function to a dart widget.

```dart
typedef DartFunction = int Function(int a, int b);

int hetuAdd(DartFunction func) {
  var func = hetu.invoke('getFunc');
  return func(6, 7);
}
```

You have to bind the Dart typedef in **init** method of the interpreter before you can use it.

```dart
await hetu.init(externalFunctions: {
  externalFunctionTypedef: {
  'DartFunction': (HTFunction function) {
    return (int a, int b) {
      // must convert the return type here to let dart know its return value type.
      return function.call([a, b]) as int;
    };
  },
});
```

The typedef of the unwrapper is:

```dart
typedef HTExternalFunctionTypedef = Function Function(HTFunction hetuFunction);
```

### Auto-Binding tools

**This tool is outdated and not suitable for this version of Hetu, we may fix it some time in the future.**

Thanks to [rockingdice](https://github.com/rockingdice) we now have an automated tool for auto-generate both Dart-side and Hetu-side binding declarations for any Dart classes.

Please check out this repository: [hetu-script-autobinding](https://github.com/hetu-script/hetu-script-autobinding)
