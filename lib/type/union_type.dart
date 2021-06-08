import '../grammar/semantic.dart';
import 'type.dart';

abstract class HTUnionType extends HTType {
  const HTUnionType(String moduleFullName, String libraryName)
      : super(SemanticType.unionTypeExpr, moduleFullName, libraryName);
}
