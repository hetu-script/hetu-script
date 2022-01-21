part of '../interpreter.dart';

class HTHetuClassBinding extends HTExternalClass {
  HTHetuClassBinding() : super('Hetu');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    final interpreter = object as Hetu;
    switch (varName) {
      case 'eval':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final code = positionalArgs.first as String;
          return interpreter.eval(code);
        };
      case 'createStructfromJson':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final jsonData = positionalArgs.first as Map<dynamic, dynamic>;
          return interpreter.createStructfromJson(jsonData);
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart future.
extension FutureBinding on Future {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'then':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return then((value) {
            func.call(positionalArgs: [value]);
          });
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}
