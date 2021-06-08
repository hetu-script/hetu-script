import '../grammar/semantic.dart';
import 'type.dart';

abstract class HTLiteralType extends HTType {
  const HTLiteralType(String moduleFullName, String libraryName)
      : super(SemanticType.literalTypeExpr, moduleFullName, libraryName);
}
