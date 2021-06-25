import '../object/object.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

abstract class HTStructuralType extends HTType with HTObject {
  const HTStructuralType() : super(HTLexicon.STRUCT);
}
