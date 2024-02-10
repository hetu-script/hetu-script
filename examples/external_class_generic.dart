import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Generic<T> {
  T value;

  Generic(this.value);
}

extension GenericBinding on Generic {
  dynamic htFetch(String id) {
    switch (id) {
      case 'value':
        return value;
      default:
        throw HTError.undefined(id);
    }
  }

  dynamic htAssign(String id, dynamic value) {
    switch (id) {
      case 'value':
        this.value = value;
      default:
        throw HTError.undefined(id);
    }
  }
}

class GenericClassBinding extends HTExternalClass {
  GenericClassBinding() : super('Generic');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Generic':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final typeString = typeArgs[0].toString();
          switch (typeString) {
            case 'num':
              return Generic<num>(positionalArgs[0]);
            case 'int':
              return Generic<int>(positionalArgs[0]);
            case 'float':
              return Generic<double>(positionalArgs[0]);
            case 'str':
              return Generic<String>(positionalArgs[0]);
            default:
              return Generic(positionalArgs[0]);
          }
        };
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String id) {
    var i = object as Generic;
    return i.htFetch(id);
  }

  @override
  dynamic instanceMemberSet(dynamic object, String id, dynamic value) {
    var i = object as Generic;
    return i.htAssign(id, value);
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [GenericClassBinding()]);
  hetu.eval('''
      external class Generic {
        constructor (value)
        final value
      }
      var obj = Generic<str>('hello world')
      print(obj.value)
      ''');
}
