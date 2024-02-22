import 'dart:convert';

import '../external/external_class.dart';
import '../utils/jsonify.dart';
import '../value/struct/struct.dart';
import '../hetu/hetu.dart';
import '../interpreter/interpreter.dart';
import '../error/error.dart';

class HTHetuClassBinding extends HTExternalClass {
  HTHetuClassBinding() : super('Hetu');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final hetu = instance as Hetu;
    switch (id) {
      case 'stringify':
        return ({positionalArgs, namedArgs}) =>
            hetu.lexicon.stringify(positionalArgs.first);
      case 'createStructfromJson':
        return ({positionalArgs, namedArgs}) {
          final jsonData = positionalArgs.first as Map<dynamic, dynamic>;
          return hetu.interpreter.createStructfromJson(jsonData);
        };
      case 'jsonify':
        return ({positionalArgs, namedArgs}) {
          final object = positionalArgs.first;
          if (object is HTStruct) {
            return jsonifyStruct(object);
          } else if (object is Iterable) {
            return jsonifyList(object);
          } else if (isJsonDataType(object)) {
            return hetu.lexicon.stringify(object);
          } else {
            return jsonEncode(object);
          }
        };
      case 'eval':
        return ({positionalArgs, namedArgs}) {
          final code = positionalArgs.first as String;
          final HTContext savedContext = hetu.interpreter.getContext();
          final result = hetu.eval(code);
          hetu.interpreter.setContext(context: savedContext);
          return result;
        };
      case 'require':
        return ({positionalArgs, namedArgs}) =>
            hetu.require(positionalArgs.first);
      case 'help':
        return ({positionalArgs, namedArgs}) => hetu.help(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}
