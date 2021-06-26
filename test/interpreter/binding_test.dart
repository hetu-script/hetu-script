import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

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
  dynamic htFetch(String field) {
    switch (field) {
      case 'familyName':
        return familyName;
      case 'firstName':
        return firstName;
      default:
        throw HTError.undefined(field);
    }
  }
}

class NameClassBinding extends HTExternalClass {
  NameClassBinding() : super('Name');

  @override
  dynamic instanceMemberGet(dynamic object, String field) =>
      (object as Name).htFetch(field);
}

extension ProfileBinding on Profile {
  dynamic htFetch(String field) {
    switch (field) {
      case 'name':
        return name;
      case 'isCivilian':
        return isCivilian;
      default:
        throw HTError.undefined(field);
    }
  }

  void htAssign(String field, dynamic varValue) {
    switch (field) {
      case 'isCivilian':
        isCivilian = varValue;
        break;
      default:
        throw HTError.undefined(field);
    }
  }
}

class ProfileClassBinding extends HTExternalClass {
  ProfileClassBinding() : super('Profile');

  @override
  dynamic memberGet(String field, {bool error = true}) {
    switch (field) {
      case 'Profile':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Profile(positionalArgs[0], positionalArgs[1]);
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String field) =>
      (object as Profile).htFetch(field);

  @override
  dynamic instanceMemberSet(dynamic object, String field, dynamic varValue) =>
      (object as Profile).htAssign(field, varValue);
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String field, {bool error = true}) {
    switch (field) {
      case 'Person.profile':
        return Person.profile;
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  @override
  dynamic memberSet(String field, dynamic value, {bool error = true}) {
    switch (field) {
      case 'Person.profile':
        return Person.profile = value;
      default:
        throw HTError.undefined(field);
    }
  }
}

void main() {
  var hetu = Hetu();
  hetu.init(externalClasses: [
    NameClassBinding(),
    ProfileClassBinding(),
    PersonClassBinding()
  ]);

  hetu.eval('''
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
  ''', namespace: hetu.global);

  group('binding -', () {
    test('get & set', () {
      final result = hetu.eval('''
        fun bindingTest {
          Person.profile.isCivilian = false
          return Person.profile.isCivilian
        }
      ''', invokeFunc: 'bindingTest');
      expect(
        result,
        false,
      );
    });
  });
}
