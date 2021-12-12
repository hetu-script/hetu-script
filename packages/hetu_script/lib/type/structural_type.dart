import '../value/entity.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

/// A type checks interfaces rather than type ids.
class HTStructuralType extends HTType with HTEntity {
  const HTStructuralType() : super(HTLexicon.kStruct);

  @override
  String toString() {
    var typeString = StringBuffer();
    typeString.write(HTLexicon.curlyLeft);
    typeString.write(HTLexicon.curlyRight);
    return typeString.toString();
  }

  @override
  bool isA(dynamic other) {
    if (other == HTType.any) {
      return true;
    } else if (other is HTStructuralType) {
      return true;
    } else {
      return false;
    }
  }
}
