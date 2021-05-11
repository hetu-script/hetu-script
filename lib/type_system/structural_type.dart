import '../implementation/object.dart';
import '../common/lexicon.dart';
import 'type.dart';

abstract class HTStructuralType extends HTType with HTObject {
  const HTStructuralType() : super(HTLexicon.STRUCT);
}
