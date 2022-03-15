// import '../error/error.dart';
import 'token.dart';
import '../grammar/lexicon2.dart';
import '../grammar/lexicon_impl.dart';
import 'package:characters/characters.dart';

extension on String {
  /// Whether this string is empty or contains only white space characters.
  bool get isBlank => isEmpty || trim() == '';
  bool get isNotBlank => !isBlank;
}

const kNewLine = '\n';

class HTLexer {
  final HTLexicon lexicon;

  HTLexer({HTLexicon? lexicon}) : lexicon = lexicon ?? HTDefaultLexicon();

  List<Token> lex(String content, {int line = 1, int column = 1, int pos = 0}) {
    final tokens = <Token>[];
    final iter = content.characters.iterator;
    final currentLineOfTokens = <Token>[];

    void handleEndOfLine([int? offset]) {
      if (currentLineOfTokens.isNotEmpty) {
        if (lexicon.autoSemicolonInsertAtStart
            .contains(currentLineOfTokens.first.type)) {
          /// Add semicolon before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (tokens.isNotEmpty &&
              !lexicon.unfinishedTokens.contains(tokens.last.type)) {
            tokens.add(Token(
                lexicon.endOfStatementMark,
                line,
                1,
                currentLineOfTokens.first.offset +
                    currentLineOfTokens.first.length,
                0));
          }
          tokens.addAll(currentLineOfTokens);
        } else if (currentLineOfTokens.last.type == lexicon.kReturn) {
          tokens.addAll(currentLineOfTokens);
          tokens.add(Token(
              lexicon.endOfStatementMark,
              line,
              column + 1,
              currentLineOfTokens.last.offset + currentLineOfTokens.last.length,
              0));
        } else {
          tokens.addAll(currentLineOfTokens);
        }
      } else {
        tokens.add(TokenEmptyLine(line, column, pos));
      }
      ++line;
      // empty line counts as a character
      if (offset == null) {
        pos += 1;
      } else {
        pos = offset + 1;
      }
      currentLineOfTokens.clear();
    }

    void moveNext(String char) {
      column += char.length;
      pos += char.length;
      if (char == kNewLine) {
        ++line;
        handleEndOfLine(pos);
      }
    }

    String getWord() {
      final buffer = StringBuffer();
      do {
        final current = iter.current;
        if (current.isNotBlank) {
          buffer.write(current);
          moveNext(current);
        } else {
          return buffer.toString();
        }
      } while (iter.moveNext());
      return buffer.toString();
    }

    while (iter.moveNext()) {
      final current = iter.current;
      if (current.isNotBlank) {
        final word = getWord();
        tokens.add(Token(word, line, column, pos, word.length));
      } else {
        moveNext(current);
      }
    }

    return tokens;
  }
}
