---
title: Communicating with Dart
---

# Communicating with Dart

There are three ways to communicate with Dart: Primitive value, Json, Binding. They have pros and cons respectively. You can choose the style best suits your needs.

# Primitive value

For these kind of values, their bindings are pre-included within the script source. And they are specificaly handled by the interpreter. Thus you can pass and get them directly.

- null
- bool
- int
- double (it is called float in the script)
- String
- List\<dynamic\>
- Map\<dynamic, dynamic\>
- Function

You can get primitive value from Hetu by the return value of Interpreter's **invoke** function, and pass object from Dart to Hetu by the positionalArgs and namedArgs of the invoke function methods:

```dart
final result = hetu.invoke('calculate', positionalArgs: [6, 7], namedArgs: {'isFloat': true};
// equivalent in script
// final result = calculate(6, 7, isFloat: true)
```

You can directly access and set the sub value of a List and Map directly by '[]' operator and call a Dart Function by '()' operator in script.

# Json

The HTStruct object in Dart code, or a struct object in the script, has builtin method: toJson() and fromJson() on its root prototype. So you can pass complex data set in this form between script and Dart.

In script:

```kotlin
fun main (data) {
  var book = prototype.fromJson(data)
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

Primitives and Json are a quick way to pass around values without any binding. However, if you want to create a Dart object, or to call a Dart function more efficiently, you have to tell the script the exact definition of the external functions and classes.

# Binding

## External function

External functions in dart for use in Hetu have following type:

```dart
/// typedef of external function for binding.
typedef HTExternalFunction = dynamic Function(
    HTEntity entity,
    {List<dynamic> positionalArgs,
    Map<String, dynamic> namedArgs,
    List<HTType> typeArgs});
```

or even you can directy write it as a Dart Function:

```dart
await hetu.init(externalFunctions: {
  'hello': () => {'greeting': 'hello'},
});
```

It's easier to write and read in Dart Function form. However, this way the Interpreter will have to use Dart's **Function.apply** feature to call it. This is normally slower and inefficient than direct call.

To call Dart functions in Hetu, define those dart funtion in Hetu with **external** keyword and init Hetu with **externalFunctions** argument.

```dart
await hetu.init(externalFunctions: {
  // you can omit the type, and keep the correct type parameter names,
  // this way Dart will still count it as HTExternalFunction
  'hello': (context, {positionalArgs, namedArgs, typeArgs}) => {'greeting': 'hello'},
});
```

Then you can call those functions in Hetu.

```typescript
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalFunctions: {
    'hello': (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) => {'greeting': 'hello'},
  });
  await hetu.eval(r'''
      external fun hello
      fun main {
        var dartValue = hello()
        print('dart value:', dartValue)
        dartValue['foo'] = 'bar'
        return dartValue
      }''');

  var hetuValue = hetu.invoke('main');

  print('hetu value: $hetuValue');
}
```

And the output should be:

```
dart value: {greeting: hello}
hetu value: {greeting: hello, foo: bar}
```

## External methods in classes

It's possible for a Hetu class to have a external method, even if other part of this class is Hetu. In this case, the first argument passed from the script will be the instance instead of the namespace.

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

## External getter

For external getter, you don't need to have a external function or external method typed function. You can directly return the value in the dart code.

## Binding a full class

It's possible to use Dart object with full class definition in Hetu.

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

## Typedef of Dart function

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

## Auto-Binding tools

**This tool is outdated and not suitable for this version of Hetu, we may fix it some time in the future.**

Thanks to [rockingdice](https://github.com/rockingdice) we now have an automated tool for auto-generate both Dart-side and Hetu-side binding declarations for any Dart classes.

Please check out this repository: [hetu-script-autobinding](https://github.com/hetu-script/hetu-script-autobinding)
