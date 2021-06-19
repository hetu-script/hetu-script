import 'package:hetu_script/hetu_script.dart';

class Generic<T> {
  T value;

  Generic(this.value);
}

extension GenericBinding on Generic {
  dynamic htFetch(String field) {
    switch (field) {
      case 'value':
        return value;
      default:
        throw HTError.undefined(field);
    }
  }

  dynamic htAssign(String field, dynamic varValue) {
    switch (field) {
      case 'value':
        value = varValue;
        break;
      default:
        throw HTError.undefined(field);
    }
  }
}

class GenericClassBinding extends HTExternalClass {
  GenericClassBinding() : super('Generic');

  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'Generic':
        return (
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
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String field) {
    var i = object as Generic;
    return i.htFetch(field);
  }

  @override
  dynamic instanceMemberSet(dynamic object, String field, dynamic varValue) {
    var i = object as Generic;
    return i.htAssign(field, varValue);
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [GenericClassBinding()]);
  await hetu.eval('''
      external class Generic {
        construct (value)
        const value
      }
      fun main {
        var obj = Generic<str>('hello world')
        print(obj.value)
      }
      ''', invokeFunc: 'main');
}
