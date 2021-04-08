import 'package:hetu_script/hetu_script.dart';

class Generic<T> {
  T value;

  Generic(this.value);
}

extension GenericBinding on Generic {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'value':
        return value;
      default:
        throw HTError.undefined(varName);
    }
  }

  dynamic htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'value':
        value = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class GenericClassBinding extends HTExternalClass {
  GenericClassBinding() : super('Generic');

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Generic<num>':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Generic<num>(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as Generic;
    return i.htFetch(varName);
  }

  @override
  dynamic instanceMemberSet(dynamic object, String varName, dynamic varValue) {
    var i = object as Generic;
    return i.htAssign(varName, varValue);
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
        var obj = Generic<num>(42)
        print(obj.value)
      }
      ''', invokeFunc: 'main');
}
