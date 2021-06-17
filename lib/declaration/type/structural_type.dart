import '../object.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

abstract class HTStructuralType extends HTType with HTObject {
  const HTStructuralType(String moduleFullName, String libraryName)
      : super(HTLexicon.STRUCT, moduleFullName, libraryName);
}
