# Communicating with Dart

There are three ways to communicate with Dart: Builtin value, Json, Binding. They have pros and cons respectively. You can choose the style best suits your needs.

## How to pass values

You can get value from Hetu by the return value of Interpreter's **invoke** function, and pass object from Dart to Hetu by the positionalArgs and namedArgs of the invoke function methods:

```dart
final result = hetu.invoke('calculate', positionalArgs: [6, 7], namedArgs: {'isFloat': true};
// equivalent in script
// final result = calculate(6, 7, isFloat: true)
```

## Builtin values

For these kind of values, their bindings are pre-included within the interpreter. Thus you can pass, get and modify them directly within script.

- null
- bool
- int
- double (it is called float in the script)
- String (it is called str in the script)
- List\<dynamic\>
- Set\<dynamic>
- Map\<dynamic, dynamic\>
- Function

You can directly access and set the sub value of a List and Map directly by '[]' operator and call a Dart Function by '()' operator in script.

## Json

The HTStruct object in Dart code can be used like a map to get and set members by **[]** operator in Dart. And it has builtin method: toJson() and fromJson() on its root prototype in script. So you can pass complex data set in this form between script and Dart.

In script:

```kotlin
function main (data) {
  var book = Prototype.fromJson(data)
  print(book)
}
```

In dart:

```dart
final Map<String, dynamic> data = {
  'id': 324,
  'title': 'Catcher in the Rye',
}
hetu.invoke('main', positionalArgs: [data]);
```

output:

```javascript
{
  id: 324,
  title: 'Catcher in the Rye',
}
```

## Binding

Primitives and Json are a quick way to pass around values without any binding. However, if you want to create a Dart object, or to call a Dart function more efficiently, you have to tell the script the exact definition of the external functions and classes.

### External function

You can directy bind a Dart function as it is:

```dart
await hetu.init(externalFunctions: {
  'hello': () => {'greeting': 'hello'},
});
```

It's easier to write and read in Dart Function form. However, this way the Interpreter will have to use Dart's **Function.apply** feature to call it. This is normally slower and inefficient than direct call.

Or you can define a external functions in dart for use in Hetu with following type:

```dart
/// typedef of external function for binding.
typedef HTExternalFunction = dynamic Function(
    HTEntity entity,
    {List<dynamic> positionalArgs,
    Map<String, dynamic> namedArgs,
    List<HTType> typeArgs});
```

Then define those dart funtion in Hetu with **external** keyword and init Hetu with **externalFunctions** argument. Then you can call those functions in Hetu.

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) => {'greeting': 'Hello from Dart!'},
  });
  final hetuValue = hetu.eval(r'''
      external function hello
      var dartValue = hello()
      dartValue['reply'] = 'Hi, this is Hetu.'
      dartValue // the script will return the value of it's last expression
      ''');

  print('hetu value: $hetuValue');
}
```

And the output should be:

```
hetu value: {'greeting': 'Hello from Dart!', 'reply': 'Hi, this is Hetu.'}
```

### External methods in classes

A Hetu class could have a external method, even if other part of this class is all Hetu.

When called, the first argument passed from the script will be the instance instead of the namespace.

For example, we have the following class with a external method:

```dart
class Someone {
  external function calculate
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
  external function sing
}
```

Everything else you should do is the same to a external method on a class.

### External class

You can use a Dart object with full class definition in Hetu.

To achieve this, you have to write a full definition of that class in Hetu, which includes 4 parts of code:

- Original class definition of the class you intended to use in Hetu. For Dart & Flutter, this is the part where you already have when you import a library.

- An [extension](https://dart.dev/guides/language/extension-methods) on that class which providing **htFetch & htAssign** methods. This part is used for dynamic reflection in Hetu and should return members of this class.

- A binding definition of that class, which extends **HTExternalClass** interface provided by Hetu's dart lib, and provides **memberGet, memberSet, instanceMemberGet, instanceMemberSet** methods. You have to bind a instance of this class with method [**bindExternalClass()**](../../api_reference/dart/readme.md) on the interpreter. This part is used for access to the constructor and static members of that class.

- Declare that class with keyword **external** in Hetu script (includes its members' declaration). This part is used for Hetu to understand the structure and type of this class, and is used for syntax check and argument default values, etc.

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
  dynamic htFetch(String id) {
    switch (id) {
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
        throw HTError.undefined(id);
    }
  }

  void htAssign(String id, dynamic value) {
    switch (id) {
      case 'name':
        name = value;
        break;
      case 'race':
        race = value;
        break;
      default:
        throw HTError.undefined(id);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id) {
    switch (id) {
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
        throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value) {
    switch (id) {
      case 'Person.race':
        throw HTError.immutable(id);
      case 'Person.level':
        return Person.level = value;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id) {
    var i = object as Person;
    return i.htFetch(id);
  }

  @override
  void instanceMemberSet(dynamic object, String id, dynamic value) {
    var i = object as Person;
    i.htAssign(id, value);
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [PersonClassBinding()]);
  hetu.eval('''
      external class Person {
        var race: str
        constructor([name: str = 'Jimmy', race: str = 'Caucasian']);
        get child
        static function meaning(n: num)
        static get level
        static set level (value: str)
        constructor withName(name: str, [race: str = 'Caucasian'])
        var name
        function greeting(tag: str)
      }
      function main {
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
      ''', type: HTResourceType.hetuModule, invoke: 'main');
}
```

#### External getter

For external getter, you don't need a full external function definition on **external class binding** or **extension on instance**. You can directly return the value in the dart code.

```dart
class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id) {
    case 'Person.level':
      return Person.level;
    default:
      throw HTError.undefined(id);
  }
}
```

#### Partial binding

You don't always need all of the definitions and declarations as the example above.

If you defined an external class binding without instanceMemberGet, instanceMemberSet and the extension on instance, you **are limited to access this class's static members and constructors with 'className.memberName'**.

If you omit the memberGet & memberSet on external class binding, and just define instanceMemberGet, instanceMemberSet and the extension on instance, you can access the instance member of this Dart instance, but **cannot access to its static class member & constructors**.

### Typedef of Dart function

Sometimes, we want to return a pure Dart function from the script side.For example, the onPressed parameter of a Widget's constructor. It is possible to do so with a **external function typedef declaration**, it is a brackets after the function keyword.

In Hetu script, we have this function:

```dart
function [DartFunction] add(a: num, b: num) -> num {
  return a + b
}

function getFunc {
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

Thanks to [rockingdice](https://github.com/rockingdice) & [CJChen98](https://github.com/CJChen98) we now have an automated tool for auto-generate both Dart-side and Hetu-side binding declarations for any Dart classes.

Please check out this repository: [hetu-script-autobinding](https://github.com/hetu-script/hetu-script-autobinding)

_This tool is maintained by third party, thus we cannot guarantee it is updated to the latest version of Hetu. If you have any questions, you can [create an issue](https://github.com/hetu-script/hetu-script-autobinding/issues)._
