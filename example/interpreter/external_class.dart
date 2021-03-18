import 'package:hetu_script/hetu_script.dart';

class Person {
  static String race = 'Caucasian';
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
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
        return HTTypeId('Person');
      case 'toString':
        return toString;
      case 'name':
        return name;
      case 'greeting':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => greeting();
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
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Person':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => Person();
      case 'Person.withName':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            Person.withName(name: namedArgs['name']);
      case 'meaning':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => Person.meaning(positionalArgs[0]);
      case 'race':
        return Person.race;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'race':
        return Person.race = value;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  dynamic instanceFetch(dynamic instance, String varName) {
    var i = instance as Person;
    return i.htFetch(varName);
  }

  @override
  void instanceAssign(dynamic instance, String varName, dynamic value) {
    var i = instance as Person;
    i.htAssign(varName, value);
  }
}

void main() async {
  var hetu = HTInterpreter();

  await hetu.init(externalClasses: {'Person': PersonClassBinding()});

  await hetu.eval('''
      external class Person {
        static var race
        static fun meaning (n: num)
        construct
        get child
        construct withName({name: String})
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

        print('My race is', Person.race)
        Person.race = 'Reptile'
        print('Oh no! My race turned into', Person.race)

        print(Person.meaning(42))
      }
      ''', invokeFunc: 'main');
}
