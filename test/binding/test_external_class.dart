import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  String name;
  Person(this.name);
}

extension PersonBinding on Person {
  dynamic htFetch(String id) {}

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
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person':
        return ({positionalArgs, namedArgs}) => Person(positionalArgs[0]);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value,
      {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id,
      {bool ignoreUndefined = false}) {
    var i = object as Person;
    return i.htFetch(id);
  }

  @override
  void instanceMemberSet(dynamic object, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    var i = object as Person;
    i.htAssign(id, value);
  }
}
