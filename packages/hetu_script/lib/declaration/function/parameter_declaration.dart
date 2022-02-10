import '../../type/type.dart';
import '../../source/source.dart';
import '../namespace/declaration_namespace.dart';
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
  HTParameterDeclaration(String id,
      {HTDeclarationNamespace? closure,
      HTSource? source,
      HTType? declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id,
            closure: closure,
            source: source,
            declType: declType,
            isMutable: true);

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
    return HTParameterDeclaration(id!,
        closure: closure,
        declType: declType,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
