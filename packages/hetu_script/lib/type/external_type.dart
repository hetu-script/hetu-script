import '../grammar/constant.dart';
import '../lexicon/lexicon.dart';
import 'type.dart';

// An unknown object type passed into script from other language
class HTExternalType extends HTType {
  const HTExternalType(String id) : super(id);
  @override
  String toString() {
    return '${Semantic.extern} ${HTLexicon.kType} $id';
  }
}
