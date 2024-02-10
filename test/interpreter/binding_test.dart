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

extension NameBinding on Name {
  dynamic htFetch(String id) {
    switch (id) {
      case 'familyName':
        return familyName;
      case 'firstName':
        return firstName;
      default:
        throw HTError.undefined(id);
    }
  }
}

class NameClassBinding extends HTExternalClass {
  NameClassBinding() : super('Name');

  @override
  dynamic instanceMemberGet(dynamic object, String id) =>
      (object as Name).htFetch(id);
}

extension ProfileBinding on Profile {
  dynamic htFetch(String id) {
    switch (id) {
      case 'name':
        return name;
      case 'isCivilian':
        return isCivilian;
      default:
        throw HTError.undefined(id);
    }
  }

  void htAssign(String id, dynamic value) {
    switch (id) {
      case 'isCivilian':
        isCivilian = value;
        break;
      default:
        throw HTError.undefined(id);
    }
  }
}

class ProfileClassBinding extends HTExternalClass {
  ProfileClassBinding() : super('Profile');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Profile':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Profile(positionalArgs[0], positionalArgs[1]);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id) =>
      (object as Profile).htFetch(id);

  @override
  dynamic instanceMemberSet(dynamic object, String id, dynamic value) =>
      (object as Profile).htAssign(id, value);
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Person.profile':
        return Person.profile;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic memberSet(String id, dynamic value, {String? from}) {
    switch (id) {
      case 'Person.profile':
        return Person.profile = value;
      default:
        throw HTError.undefined(id);
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
    var familyName: str;
    var firstName: str;
  }
  external class Profile {
    var name
    constructor (familyName: str, firstName: str)

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
  });
}
