import 'package:hetu_script/hetu_script.dart';

class Person {
  static String race = 'Caucasian';
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  Person();
  Person.withName([this.name = 'some guy']);

  String? name = 'default name';
  void greeting() {
    print('Hi! I\'m $name');
  }
}

extension PersonBinding on Person {
  dynamic ht_fetch(String varName) {
    switch (varName) {
      case 'typeid':
        return HTTypeId('Person');
      case 'toString':
        return toString;
      case 'name':
        return name;
      case 'greeting':
        return greeting;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  void ht_assign(String varName, dynamic value) {
    switch (varName) {
      case 'name':
        name = value;
        break;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class PersonHTBinding extends HTExternClass {
  PersonHTBinding() : super('Person');

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Person':
        return () => Person();
      case 'Person.withName':
        return ([name = 'some guy']) => Person.withName(name);
      case 'meaning':
        return (int n) => Person.meaning(n);
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
  dynamic instanceFetch(dynamic instance, String id) {
    var i = instance as Person;
    return i.ht_fetch(id);
  }

  @override
  void instanceAssign(dynamic instance, String id, dynamic value) {
    var i = instance as Person;
    i.ht_assign(id, value);
  }
}

void main() {
  var hetu = HTInterpreter();

  hetu.bindExternalClass('Person', PersonHTBinding());

  hetu.eval('''
      external class Person {
        static var race
        static fun meaning (n: num)
        construct
        get child
        construct withName
        var name
        fun greeting
      }
      fun main {
        let p1: Person = Person()
        print(p1.typeid)
        print(p1.name)
        var p2 = Person.withName('Jimmy')
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
