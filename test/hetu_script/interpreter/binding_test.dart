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
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'familyName':
        return familyName;
      case 'firstName':
        return firstName;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class NameClassBinding extends HTExternalClass {
  NameClassBinding() : super('Name');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Name).htFetch(varName);
}

extension ProfileBinding on Profile {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'name':
        return name;
      case 'isCivilian':
        return isCivilian;
      default:
        throw HTError.undefined(varName);
    }
  }

  void htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'isCivilian':
        isCivilian = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class ProfileClassBinding extends HTExternalClass {
  ProfileClassBinding() : super('Profile');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Profile':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Profile(positionalArgs[0], positionalArgs[1]);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Profile).htFetch(varName);

  @override
  dynamic instanceMemberSet(dynamic object, String varName, dynamic varValue) =>
      (object as Profile).htAssign(varName, varValue);
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Person.profile':
        return Person.profile;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic memberSet(String varName, dynamic varValue, {String? from}) {
    switch (varName) {
      case 'Person.profile':
        return Person.profile = varValue;
      default:
        throw HTError.undefined(varName);
    }
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [
    NameClassBinding(),
    ProfileClassBinding(),
    PersonClassBinding()
  ]);

  hetu.eval(r'''
  external class Name {
    var familyName: str;
    var firstName: str;
  }
  external class Profile {
    var name
    construct (familyName: str, firstName: str)

    get isCivilian -> bool
    set isCivilian(value: bool)
  }
  external class Person {
    static get profile -> Profile
    static set profile(p: Profile)
  }
  ''', globallyImport: true);

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
