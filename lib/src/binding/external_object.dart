import '../interpreter.dart';
import '../object.dart';
import '../type.dart';
import '../lexicon.dart';
import '../errors.dart';

/// Class for external object.
class HTExternalObject<T> with HTObject, InterpreterRef {
  @override
  HTType get rtType => memberGet(HTLexicon.rtType);

  /// the external object.
  T externObject;

  /// Create a external class object.
  HTExternalObject(this.externObject, Interpreter interpreter) {
    this.interpreter = interpreter;
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    final typeString = externObject.runtimeType.toString();
    final id = HTType.parseBaseType(typeString);
    if (interpreter.containsExternalClass(id)) {
      final externClass = interpreter.fetchExternalClass(id);
      return externClass.instanceMemberGet(externObject, varName);
    } else {
      switch (varName) {
        case 'runtimeType':
          return HTUnknownType(typeString);
        case 'toString':
          return ({positionalArgs, namedArgs, typeArgs}) =>
              externObject.toString();
        default:
          throw HTError.unknownType(typeString);
      }
    }
  }
}
