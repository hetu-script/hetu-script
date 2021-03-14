import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/src/value.dart';

class DartPerson {
  static var race = 'Caucasian';
  static String meaning(int n) => 'The meaning of life is $n';
  DartPerson();
  DartPerson.withName([this.name = 'some guy']);

  String name;
  void greeting() {
    print('Hi! I\'m $name');
  }
}

class DartPersonWrapper extends HT_ExternObject<DartPerson> {
  DartPersonWrapper(DartPerson value) : super(value);

  @override
  final typeid = HT_TypeId('Person');

  @override
  dynamic getProperty(String id) {
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
  void setProperty(String id, dynamic value) {
    switch (id) {
      case 'name':
        externObject.name = value;
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }
}

void main() async {
  var hetu = HT_Interpreter();

  hetu.bindExternalClass(id, namespace)

  hetu.eval('''
      external class Person {
        static var race
        static fun meaning (n: num) {}
        init {} // 必须有空括号
        init withName {}
        var name
        fun greeting
      }
      fun main {
        var p = Person.withName('Jimmy')
        print(p.name)
        p.name = 'John'
        p.greeting();

        print('My race is', Person.race)
        Person.race = 'Reptile'
        print('Oh no! My race turned into', Person.race)

        print(Person.meaning(42))
      }
      ''', invokeFunc: 'main');
}
