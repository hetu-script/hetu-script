import 'package:hetu_script/hetu_script.dart';

import '../interpreter.dart';
import '../object.dart';
import '../type.dart';
import '../lexicon.dart';
import '../errors.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  HTType get rtType => memberGet(HTLexicon.rtType);

  /// the external object.
  final T externalObject;
  late final _typeString;
  late final HTExternalClass? externalClass;

  /// Create a external class object.
  HTExternalInstance(this.externalObject, Interpreter interpreter) {
    this.interpreter = interpreter;

    _typeString = externalObject.runtimeType.toString();
    final id = HTType.parseBaseType(_typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (externalClass != null) {
      return externalClass!.instanceMemberGet(externalObject, varName);
    } else {
      switch (varName) {
        case 'runtimeType':
          return HTUnknownType(_typeString);
        case 'toString':
          return ({positionalArgs, namedArgs, typeArgs}) =>
              externalObject.toString();
        default:
          throw HTError.unknownType(_typeString);
      }
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownType(_typeString);
    }
  }
}
