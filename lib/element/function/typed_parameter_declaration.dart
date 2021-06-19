import '../../type/type.dart';
import '../variable/typed_variable_declaration.dart';

class HTTypedParameterDeclaration extends HTTypedVariableDeclaration {
  final bool isOptional;

  final bool isNamed;

  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTTypedParameterDeclaration(
      String id, String moduleFullName, String libraryName,
      {HTType? declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, moduleFullName, libraryName,
            declType: declType ?? HTType.ANY, isMutable: true);

  @override
  HTTypedParameterDeclaration clone() {
    return HTTypedParameterDeclaration(id, moduleFullName, libraryName,
        isOptional: isOptional, isNamed: isNamed, isVariadic: isVariadic);
  }
}
