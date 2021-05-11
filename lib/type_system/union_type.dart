import '../common/lexicon.dart';
import 'type.dart';

abstract class HTUnionType extends HTType {
  const HTUnionType() : super(HTLexicon.unionType);
}
