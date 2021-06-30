import '../grammar/semantic.dart';
import '../grammar/lexicon.dart';
import 'type.dart';

class HTExternalType extends HTType {
  @override
  String toString() {
    return '${SemanticNames.extern} ${HTLexicon.TYPE}${HTLexicon.colon} $id';
  }

  const HTExternalType(String id) : super(id);
}
