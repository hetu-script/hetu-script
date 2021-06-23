import '../../type/type.dart';
import '../element.dart';

class HTTypedParameterDeclaration extends HTElement {
  @override
  final String id;

  final bool isOptional;

  final bool isNamed;

  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTTypedParameterDeclaration(this.id,
      {HTType? declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id: id, declType: declType ?? HTType.ANY, isMutable: true);

  @override
  HTTypedParameterDeclaration clone() {
    return HTTypedParameterDeclaration(id,
        isOptional: isOptional, isNamed: isNamed, isVariadic: isVariadic);
  }
}
