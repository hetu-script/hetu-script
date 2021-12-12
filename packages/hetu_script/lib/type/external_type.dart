import '../grammar/semantic.dart';
import '../grammar/lexicon.dart';
import 'type.dart';

// An unknown object type passed into script from other language
class HTExternalType extends HTType {
  @override
  String toString() {
    return '${SemanticNames.extern} ${HTLexicon.kType}${HTLexicon.colon} $id';
  }

  const HTExternalType(String id) : super(id);
}
