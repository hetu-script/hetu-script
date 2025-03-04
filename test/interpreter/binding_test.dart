import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Name {
  final String familyName;
  final String firstName;

  Name(this.familyName, this.firstName);
}

class Profile {
  late Name name;

  bool _isCivilian = true;
  // ignore: unnecessary_getters_setters
  bool get isCivilian => _isCivilian;
  // ignore: unnecessary_getters_setters
  set isCivilian(bool value) => _isCivilian = value;

  Profile(String familyName, String firstName) {
    name = Name(familyName, firstName);
  }
}

class Person {
  static Profile profile = Profile('Riddle', 'Tom');
}

class NameClassBinding extends HTExternalClass {
  NameClassBinding() : super('Name');

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Name;

    switch (id) {
      case 'familyName':
        return object.familyName;
      case 'firstName':
        return object.firstName;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class ProfileClassBinding extends HTExternalClass {
  ProfileClassBinding() : super('Profile');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Profile':
        return (HTObject entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Profile(positionalArgs[0], positionalArgs[1]);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Profile;
    switch (id) {
      case 'name':
        return object.name;
      case 'isCivilian':
        return object.isCivilian;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    final object = instance as Profile;
    switch (id) {
      case 'isCivilian':
        object.isCivilian = value;
        break;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person.profile':
        return Person.profile;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic memberSet(String id, dynamic value,
      {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person.profile':
        return Person.profile = value;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init(externalClasses: [
    NameClassBinding(),
    ProfileClassBinding(),
    PersonClassBinding()
  ]);

  hetu.eval(
    r'''
  external class Name {
    var familyName: string;
    var firstName: string;
  }
  external class Profile {
    var name
    constructor (familyName: string, firstName: string)

    get isCivilian -> bool
    set isCivilian(value: bool)
  }
  external class Person {
    static get profile -> Profile
    static set profile(p: Profile)
  }
  ''',
    globallyImport: true,
    type: HTResourceType.hetuModule,
  );

  group('binding -', () {
    test('get & set', () {
      final result = hetu.eval(r'''
        Person.profile.isCivilian = false
      ''');
      expect(
        result,
        false,
      );
    });

    test('external function within class', () {
      hetu.interpreter.bindExternalMethod('Test::externalFunc', (
          {object, positionalArgs, namedArgs}) {
        return 'external function called';
      });

      final result = hetu.eval(r'''
        class Test {
          external function externalFunc
        }
        final t = Test()
        t.externalFunc()
      ''');
      expect(
        result,
        'external function called',
      );
    });

    test('external function within explicit namespace', () {
      hetu.interpreter.bindExternalFunction('Somespace::externalFunc', (
          {positionalArgs, namedArgs}) {
        return 'external function called';
      });

      final result = hetu.eval(r'''
        namespace Somespace {
          external function externalFunc
        }
        Somespace.externalFunc()
      ''');
      expect(
        result,
        'external function called',
      );
    });
  });
}
