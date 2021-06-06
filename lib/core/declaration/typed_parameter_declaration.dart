import '../../type_system/type.dart';
import 'typed_variable_declaration.dart';

class TypedParameterDeclaration extends TypedVariableDeclaration {
  final bool isOptional;

  final bool isNamed;

  final bool isVariadic;

  /// Create a standard [HTParameter].
  TypedParameterDeclaration(
      String id, String moduleFullName, String libraryName,
      {HTType? declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, moduleFullName, libraryName,
            declType: declType ?? HTType.ANY, isMutable: true);

  @override
  TypedParameterDeclaration clone() {
    return TypedParameterDeclaration(id, moduleFullName, libraryName,
        isOptional: isOptional, isNamed: isNamed, isVariadic: isVariadic);
  }
}
