import '../../type/generic_type_parameter.dart';

abstract class HTTypeDeclaration {
  Iterable<HTGenericTypeParameter> get genericTypeParameters;
}
