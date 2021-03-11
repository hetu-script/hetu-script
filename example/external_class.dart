import 'package:hetu_script/hetu_script.dart';

class DartPerson {
  static var race = 'Caucasian';
  static String meaning(int n) => 'the meaning of life is $n';
  String name;
  void greeting() {
    print('Hi! I\'m $name');
  }

  DartPerson();
  DartPerson.withName([this.name = 'some guy']);
}

class DartPersonWrapper extends DartPerson with HT_Reflect {
  DartPersonWrapper() : super();
  DartPersonWrapper.withName([String name = 'some guy']) : super.withName(name);

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'name':
        return name;
      case 'greeting':
        return greeting;
      default:
        throw HTErr_Undefined(id, interpreter.curFileName);
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
      final dartNamedArg = <Symbol, dynamic>{};
      for (var key in namedArgs.keys) {
        dartNamedArg[Symbol(key)] = namedArgs[key];
      }
      return Function.apply(DartPerson.meaning, positionalArgs, dartNamedArg);
    },
    // 类的 external static 变量，只能通过 getter 函数的方式获取
    'Person.__get__race': (HT_Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
      return DartPerson.race;
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
        p.greeting();

        print(Person.meaning(42))
        print('Jimmy is a', Person.race)
        
      }
      ''', invokeFunc: 'main');
}
