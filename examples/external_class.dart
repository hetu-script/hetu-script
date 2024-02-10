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
  dynamic htFetch(String id) {
    switch (id) {
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
        throw HTError.undefined(id);
    }
  }

  void htAssign(String id, dynamic value) {
    switch (id) {
      case 'name':
        name = value;
      case 'race':
        race = value;
      default:
        throw HTError.undefined(id);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
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
        throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value, {String? from}) {
    switch (id) {
      case 'Person.race':
        throw HTError.immutable(id);
      case 'Person.level':
        Person.level = value;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id) {
    var i = object as Person;
    return i.htFetch(id);
  }

  @override
  void instanceMemberSet(dynamic object, String id, dynamic value) {
    var i = object as Person;
    i.htAssign(id, value);
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [PersonClassBinding()]);
  hetu.eval('''
      external class Person {
        var race: str
        constructor([name: str = 'Jimmy', race: str = 'Caucasian']);
        get child
        static function meaning(n: num)
        static get level
        static set level (value: str)
        constructor withName(name: str, [race: str = 'Caucasian'])
        var name
        function greeting(tag: str)
      }
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
      ''');
}
