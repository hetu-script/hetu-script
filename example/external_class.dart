import 'package:hetu_script/hetu_script.dart';

class Person {
  static String race = 'Caucasian';
  static String _level = '0';
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  static String get level => _level;
  static set level(value) => _level = value;
  Person();
  Person.withName({this.name = 'some guy'});

  String name = 'default name';
  void greeting() {
    print('Hi! I\'m $name');
  }
}

extension PersonBinding on Person {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'typeid':
        return const HTTypeId('Person');
      case 'toString':
        return toString;
      case 'name':
        return name;
      case 'greeting':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            greeting();
      case 'child':
        return child;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  void htAssign(String varName, dynamic value) {
    switch (varName) {
      case 'name':
        name = value;
        break;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Person':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            Person();
      case 'Person.withName':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            Person.withName(name: namedArgs['name']);
      case 'Person.meaning':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.race':
        return Person.race;
      case 'Person.level':
        return Person.level;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Person.race':
        return Person.race = value;
      case 'Person.level':
        return Person.level = value;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String varName) {
    var i = instance as Person;
    return i.htFetch(varName);
  }

  @override
  void instanceMemberSet(dynamic instance, String varName, dynamic value) {
    var i = instance as Person;
    i.htAssign(varName, value);
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [PersonClassBinding()]);
  await hetu.eval('''
      external class Person {
        static var race
        static fun meaning(n: num)
        construct
        get child
        static get level
        static set level (value: str)
        construct withName({name: str})
        var name
        fun greeting
      }
      fun main {
        let p1: Person = Person()
        print(p1.typeid)
        print(p1.name)
        var p2 = Person.withName(name: 'Jimmy')
        print(p2.name)
        p2.name = 'John'
        p2.greeting();
        print(p1.child)
        Person.level = '3'
        print(Person.level)

        print('My race is', Person.race)
        Person.race = 'Reptile'
        print('Oh no! My race turned into', Person.race)

        print(Person.meaning(42))
      }
      ''', invokeFunc: 'main');
}
