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
      default:
        throw HTError.undefined(varName);
    }
  }
}
