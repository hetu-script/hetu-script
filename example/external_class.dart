import 'package:hetu_script/hetu_script.dart';

abstract class Animal {
  String name;

  Animal([this.name = 'nameless animal']);
}

class Person extends Animal {
  static final races = <String>['Caucasian'];
  static String _level = '0';
  static String get level => _level;
  static set level(value) => _level = value;
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';

  String race;

  Person([this.race = 'Caucasian']) : super('Jerry');

  Person.withName(String name, [this.race = 'Caucasian']);

  void greeting() {
    print('Hi! I\'m $name');
  }
}

extension PersonBinding on Person {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'rtType':
        return const HTType('Person');
      case 'toString':
        return toString;
      case 'name':
        return name;
      case 'race':
        return race;
      case 'greeting':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            greeting();
      case 'child':
        return child;
      default:
        throw HTError.undefined(varName);
    }
  }

  void htAssign(String varName, dynamic value) {
    switch (varName) {
      case 'name':
        name = value;
        break;
      case 'race':
        race = value;
        break;
      default:
        throw HTError.undefined(varName);
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
                List<HTType> typeArgs = const []}) =>
            Person(positionalArgs[0]);
      case 'Person.withName':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.withName(positionalArgs[0], positionalArgs[1]);
      case 'Person.meaning':
        return (
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
  void memberSet(String varName, dynamic value,
      {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Person.race':
        throw HTError.immutable(varName);
      case 'Person.level':
        return Person.level = value;
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
  void instanceMemberSet(dynamic object, String varName, dynamic value) {
    var i = object as Person;
    i.htAssign(varName, value);
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [PersonClassBinding()]);
  await hetu.eval('''
      external abstract class Animal {
        var name: str
      }
      external class Person {
        var race: str
        construct ([race: str = 'Caucasian'])
        get child
        static fun meaning(n: num)
        static get level
        static set level (value: str)
        construct withName(name: str, [race: str = 'Caucasian'])
        var name
        fun greeting
      }
      fun main {
        // let p1: Person = Person()
        // print(p1.rtType)
        // print(p1.name)
        // print(p1.child)
        // print('My race is', p1.race)
        // p1.race = 'Reptile'
        // print('Oh no! My race turned into', p1.race)

        var p2 = Person.withName('Jimmy')
        print(p2.name)
        p2.name = 'John'
        p2.greeting();

        Person.level = '3'
        print(Person.level)

        print(Person.meaning(42))
      }
      ''', invokeFunc: 'main');
}
