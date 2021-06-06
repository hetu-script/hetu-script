import '../interpreter.dart';
import '../variable.dart';

/// An implementation of [HTVariable] for function parameter declaration.
class HTParameter extends HTVariable {
  final bool isOptional;

  final bool isNamed;

  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTParameter(
      String id, String moduleFullName, String libraryName, Hetu interpreter,
      {int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, moduleFullName, libraryName, interpreter,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);

  @override
  HTParameter clone() {
    return HTParameter(id, moduleFullName, libraryName, interpreter,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
