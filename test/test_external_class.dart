import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  String name;
  Person(this.name);
}

extension PersonBinding on Person {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'name':
        return name;
      default:
        throw HTError.undefined(varName);
    }
  }

  void htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'name':
        name = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Person':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue, {String? from}) {
    switch (varName) {
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as Person;
    return i.htFetch(varName);
  }

  @override
  void instanceMemberSet(dynamic object, String varName, dynamic varValue) {
    var i = object as Person;
    i.htAssign(varName, varValue);
  }
}
