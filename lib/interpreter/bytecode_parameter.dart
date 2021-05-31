import '../type_system/type.dart';
import '../type_system/function_type.dart' show HTParameterType;
import '../core/declaration/abstract_parameter.dart';
import 'interpreter.dart';
import 'variable.dart';

/// An implementation of [HTVariable] for function parameter declaration.
class HTParameter extends HTVariable implements AbstractParameter {
  late final HTParameterType declType;

  @override
  String get paramId => id;

  @override
  bool get isOptional => declType.isOptional;

  @override
  bool get isNamed => declType.isNamed;

  @override
  bool get isVariadic => declType.isVariadic;

  /// Create a standard [HTParameter].
  HTParameter(String id, Hetu interpreter, String moduleFullName,
      {dynamic value,
      HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      bool isOptional = false,
      bool isNamed = false,
      bool isVariadic = false})
      : declType = HTParameterType.fromType(id,
            paramType: declType,
            isOptional: isOptional,
            isNamed: isNamed,
            isVariadic: isVariadic),
        super(id, interpreter, moduleFullName,
            value: value,
            declType: declType,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);

  @override
  HTParameter clone() {
    return HTParameter(id, interpreter, moduleFullName,
        value: value,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
