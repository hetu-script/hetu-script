import 'package:hetu_script/hetu_script.dart';

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

class DartPersonWrapper extends DartPerson with HT_Reflect {
  DartPersonWrapper() : super();
  DartPersonWrapper.withName([String name = 'some guy']) : super.withName(name);

  @override
  final typeid = HT_Type('Person');

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'name':
        return name;
      case 'greeting':
        return greeting;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    switch (id) {
      case 'name':
        name = value;
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }
}

void main() async {
  var hetu = HT_Interpreter(externalFunctions: {
    'Person': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return DartPersonWrapper();
    },
    'Person.withName': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return DartPersonWrapper.withName(positionalArgs.isNotEmpty ? positionalArgs[0] : null);
    },
    'Person.meaning': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return Function.apply(
          DartPerson.meaning, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
    },
    // 类的 external static 变量，只能通过 getter, setter 函数的方式访问
    'Person.__get__race': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return DartPerson.race;
    },
    'Person.__set__race': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      DartPerson.race = positionalArgs.isNotEmpty ? positionalArgs.first : null;
    },
  });

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
