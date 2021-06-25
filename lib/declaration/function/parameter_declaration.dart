import '../../type/type.dart';
import '../declaration.dart';
import 'abstract_parameter.dart';

class HTParameterDeclaration extends HTDeclaration
    implements AbstractParameter {
  @override
  final String id;

  @override
  final bool isOptional;

  @override
  final bool isNamed;

  @override
  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTParameterDeclaration(this.id,
      {HTType? declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id: id, declType: declType ?? HTType.ANY, isMutable: true);

  @override
  String toString() {
    final typeString = StringBuffer();
    if (declType != null) {
      typeString.write('$id: ');
      typeString.write(declType.toString());
    }
    return typeString.toString();
  }

  @override
  HTParameterDeclaration clone() {
    return HTParameterDeclaration(id,
        declType: declType,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
