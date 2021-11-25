import '../value/entity.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';

/// A type checks interfaces rather than type ids.
class HTStructuralType extends HTType with HTEntity {
  const HTStructuralType() : super(HTLexicon.STRUCT);
}
