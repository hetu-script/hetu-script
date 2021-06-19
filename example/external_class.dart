import 'package:hetu_script/hetu_script.dart';

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
  dynamic htFetch(String field) {
    switch (field) {
      case 'name':
        return name;
      case 'race':
        return race;
      case 'greeting':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            greeting(positionalArgs.first);
      case 'child':
        return child;
      default:
        throw HTError.undefined(field);
    }
  }

  void htAssign(String field, dynamic varValue) {
    switch (field) {
      case 'name':
        name = varValue;
        break;
      case 'race':
        race = varValue;
        break;
      default:
        throw HTError.undefined(field);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'Person':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person(positionalArgs[0], positionalArgs[1]);
      case 'Person.withName':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.withName(positionalArgs[0],
                (positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasion'));
      case 'Person.meaning':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.level':
        return Person.level;
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  @override
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global}) {
    switch (field) {
      case 'Person.race':
        throw HTError.immutable(field);
      case 'Person.level':
        return Person.level = varValue;
      default:
        throw HTError.undefined(field);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String field) {
    var i = object as Person;
    return i.htFetch(field);
  }

  @override
  void instanceMemberSet(dynamic object, String field, dynamic varValue) {
    var i = object as Person;
    i.htAssign(field, varValue);
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [PersonClassBinding()]);
  await hetu.eval('''
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
        let p1: Person = Person()
        p1.greeting('jimmy')
        print(p1.valueType)
        print(p1.name)
        print(p1.child)
        print('My race is', p1.race)
        p1.race = 'Reptile'
        print('Oh no! My race turned into', p1.race)

        var p2 = Person.withName('Jimmy')
        print(p2.name)
        p2.name = 'John'

        Person.level = '3'
        print(Person.level)

        print(Person.meaning(42))
      }
      ''', invokeFunc: 'main');
}
