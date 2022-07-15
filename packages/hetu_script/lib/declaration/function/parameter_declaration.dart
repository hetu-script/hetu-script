// import '../../type/type.dart';
// import '../../source/source.dart';
// import '../namespace/declaration_namespace.dart';
import '../variable/variable_declaration.dart';
import 'abstract_parameter.dart';

class HTParameterDeclaration extends HTVariableDeclaration
    implements HTAbstractParameter {
  @override
  final bool isOptional;

  @override
  final bool isNamed;

  @override
  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTParameterDeclaration(
      {required super.id,
      super.closure,
      super.source,
      super.declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(isMutable: true);

  @override
  void initialize() {}

  @override
  HTParameterDeclaration clone() {
    return HTParameterDeclaration(
        id: id!,
        closure: closure,
        declType: declType,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
