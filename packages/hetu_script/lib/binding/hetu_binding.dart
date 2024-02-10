import 'dart:convert';

import 'package:hetu_script/hetu_script.dart';

import '../external/external_class.dart';
import '../utils/jsonify.dart';
import '../value/struct/struct.dart';

class HTHetuClassBinding extends HTExternalClass {
  HTHetuClassBinding() : super('Hetu');

  @override
  dynamic instanceMemberGet(dynamic object, String id) {
    final hetu = object as Hetu;
    switch (id) {
      case 'stringify':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            hetu.lexicon.stringify(positionalArgs.first);
      case 'createStructfromJson':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final jsonData = positionalArgs.first as Map<dynamic, dynamic>;
          return hetu.interpreter.createStructfromJson(jsonData);
        };
      case 'jsonify':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
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
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final code = positionalArgs.first as String;
          final HTContext savedContext = hetu.interpreter.getContext();
          final result = hetu.eval(code);
          hetu.interpreter.setContext(context: savedContext);
          return result;
        };
      case 'require':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            hetu.require(positionalArgs.first);
      case 'help':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            hetu.help(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}
