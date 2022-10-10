import '../parser/token.dart';
import 'lexicon.dart';
import 'lexicon_default_impl.dart';

abstract class HTLexer {
  HTLexicon lexicon;

  HTLexer({HTLexicon? lexicon}) : lexicon = lexicon ?? HTDefaultLexicon();

  /// Scan a string content and convert it into a linked list of tokens.
  /// The last element in the list will always be a end of file token.
  Token lex(String content, {int line = 1, int column = 1, int offset = 0});
}
