import '../external/external_class.dart';
import '../value/entity.dart';
import '../type/type.dart';
import '../error/error.dart';
import '../hetu/hetu.dart';

class HTHetuClassBinding extends HTExternalClass {
  HTHetuClassBinding() : super('Hetu');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    final hetu = object as Hetu;
    switch (varName) {
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
      case 'eval':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final code = positionalArgs.first as String;
          final savedFileName = hetu.interpreter.currentFileName;
          final savedModuleName = hetu.interpreter.bytecodeModule.id;
          final savedNamespace = hetu.interpreter.currentNamespace;
          final savedIp = hetu.interpreter.bytecodeModule.ip;
          final result = hetu.eval(code);
          hetu.interpreter.restoreStackFrame(
            clearStack: false,
            savedFileName: savedFileName,
            savedModuleName: savedModuleName,
            savedNamespace: savedNamespace,
            savedIp: savedIp,
          );
          return result;
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}
