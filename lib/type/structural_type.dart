import '../object/object.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

class HTStructuralType extends HTType with HTObject {
  const HTStructuralType() : super(HTLexicon.STRUCT);
}
