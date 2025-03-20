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

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person':
        return ({positionalArgs, namedArgs}) =>
            Person(positionalArgs[0], positionalArgs[1]);
      case 'Person.withName':
        return ({positionalArgs, namedArgs}) => Person.withName(
            positionalArgs[0],
            (positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasion'));
      case 'Person.meaning':
        return ({positionalArgs, namedArgs}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.level':
        return Person.level;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value,
      {String? from, bool defineIfAbsent = false}) {
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
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Person;
    switch (id) {
      case 'name':
        return object.name;
      case 'race':
        return object.race;
      case 'greeting':
        return ({positionalArgs, namedArgs}) =>
            object.greeting(positionalArgs.first);
      case 'child':
        return object.child;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    final object = instance as Person;
    switch (id) {
      case 'name':
        object.name = value;
      case 'race':
        object.race = value;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [PersonClassBinding()]);
  hetu.eval('''
      external class Person {
        var race: string
        constructor([name: string = 'Jimmy', race: string = 'Caucasian']);
        get child
        static function meaning(n: num)
        static get level
        static set level (value: string)
        constructor withName(name: string, [race: string = 'Caucasian'])
        var name
        function greeting(tag: string)
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
