import 'package:hetu_script/hetu_script.dart';

class DartPerson {
  static String race = 'Caucasian';
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  DartPerson();
  DartPerson.withName([this.name = 'some guy']);

  String? name = 'default name';
  void greeting() {
    print('Hi! I\'m $name');
  }
}

class DartPersonClassBinding extends HT_ExternNamespace {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'Person':
        return () => DartPersonObjectBinding(DartPerson());
      case 'Person.withName':
        return ([name = 'some guy']) => DartPersonObjectBinding(DartPerson.withName(name));
      case 'meaning':
        return (int n) => DartPerson.meaning(n);
      case 'race':
        return DartPerson.race;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    switch (id) {
      case 'race':
        return DartPerson.race = value;
      default:
        throw HTErr_Undefined(id);
    }
  }
}

class DartPersonObjectBinding extends HT_ExternObject<DartPerson> {
  DartPersonObjectBinding(DartPerson value) : super(value);

  @override
  final typeid = HT_TypeId('Person');

  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'name':
        return externObject.name;
      case 'greeting':
        return externObject.greeting;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    switch (id) {
      case 'name':
        externObject.name = value;
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }
}

void main() {
  var hetu = HT_Interpreter();

  hetu.bindExternalNamespace('Person', DartPersonClassBinding());

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
        var p1 = Person()
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
