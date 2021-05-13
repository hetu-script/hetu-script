import '../grammar/semantic.dart';
import 'type.dart';

abstract class HTUnionType extends HTType {
  const HTUnionType() : super(SemanticType.unionTypeExpr);
}
