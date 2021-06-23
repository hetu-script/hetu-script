import '../../grammar/semantic.dart';
import 'type.dart';

abstract class HTLiteralType extends HTType {
  const HTLiteralType() : super(SemanticNames.literalTypeExpr);
}
