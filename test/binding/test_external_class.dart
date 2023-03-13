import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  String name;
  Person(this.name);
}

extension PersonBinding on Person {
  dynamic htFetch(String id) {
    switch (id) {
      case 'name':
        return name;
      default:
        throw HTError.undefined(id);
    }
  }

  void htAssign(String id, dynamic value) {
    switch (id) {
      case 'name':
        name = value;
        break;
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
            Person(positionalArgs[0]);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value, {String? from}) {
    switch (id) {
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
