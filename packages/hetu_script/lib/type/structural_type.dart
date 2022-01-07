import '../value/entity.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

/// A type checks interfaces rather than type ids.
class HTStructuralType extends HTType with HTEntity {
  final Map<String, HTType> fieldTypes;

  const HTStructuralType({this.fieldTypes = const {}})
      : super(HTLexicon.kStruct);

  @override
  String toString() {
    var typeString = StringBuffer();
    if (fieldTypes.isEmpty) {
      typeString.writeln('${HTLexicon.bracesLeft}${HTLexicon.bracesRight}');
    } else {
      typeString.writeln(HTLexicon.bracesLeft);
      for (var i = 0; i < fieldTypes.length; ++i) {
        final key = fieldTypes.keys.elementAt(i);
        typeString.write('  $key');
        final fieldTypeString = fieldTypes[key].toString();
        typeString.write(' $fieldTypeString');
        if (i < fieldTypes.length - 1) {
          typeString.writeln(HTLexicon.comma);
        }
      }
      typeString.write(HTLexicon.bracesRight);
    }
    return typeString.toString();
  }

  @override
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other == HTType.any) {
      return true;
    } else if (other is HTStructuralType) {
      if (other.fieldTypes.isEmpty) {
        return true;
      } else {
        if (other.fieldTypes.length != fieldTypes.length) {
          return false;
        } else {
          for (final key in fieldTypes.keys) {
            if (!other.fieldTypes.containsKey(key)) {
              return false;
            } else {
              if (fieldTypes[key]!.isNotA(other.fieldTypes[key])) {
                return false;
              }
            }
          }
          return true;
        }
      }
    } else {
      return false;
    }
  }
}
