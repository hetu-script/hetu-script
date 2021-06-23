import '../../interpreter/interpreter.dart';
import '../variable/variable.dart';

// TODO: parameter's initializer must be a const expression.

/// An implementation of [HTVariable] for function parameter declaration.
class HTParameter extends HTVariable {
  final bool isOptional;

  final bool isNamed;

  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTParameter(String id, Hetu interpreter,
      {int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);

  @override
  HTParameter clone() {
    return HTParameter(id, interpreter,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
