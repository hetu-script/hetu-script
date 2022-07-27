import '../../value/namespace/namespace.dart';
import '../variable/variable.dart';
import '../../declaration/function/abstract_parameter.dart';

// TODO: parameter's initializer must be a const expression.

/// An implementation of [HTVariable] for function parameter declaration.
class HTParameter extends HTVariable implements HTAbstractParameter {
  final HTNamespace? _closure;

  @override
  HTNamespace? get closure => _closure;

  @override
  final bool isVariadic;

  @override
  final bool isOptional;

  @override
  final bool isNamed;

  @override
  final bool isInitialization;

  /// Create a standard [HTParameter].
  HTParameter({
    required super.id,
    super.interpreter,
    super.fileName,
    super.moduleName,
    super.closure,
    super.declType,
    super.definitionIp,
    super.definitionLine,
    super.definitionColumn,
    this.isVariadic = false,
    this.isOptional = false,
    this.isNamed = false,
    this.isInitialization = false,
  })  : _closure = closure,
        super(isMutable: true);

  // @override
  // String toString() {
  //   final typeString = StringBuffer();
  //   if (declType != null) {
  //     typeString.write('$id: ');
  //     typeString.write(declType.toString());
  //   }
  //   return typeString.toString();
  // }

  @override
  void resolve({bool resolveType = false}) {
    super.resolve(resolveType: false);
  }

  @override
  HTParameter clone() {
    return HTParameter(
      id: id!,
      interpreter: interpreter,
      fileName: fileName,
      moduleName: moduleName,
      closure: closure,
      declType: declType,
      definitionIp: definitionIp,
      definitionLine: definitionLine,
      definitionColumn: definitionColumn,
      isVariadic: isVariadic,
      isOptional: isOptional,
      isNamed: isNamed,
      isInitialization: isInitialization,
    );
  }
}
