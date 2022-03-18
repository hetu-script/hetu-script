// import '../error/error.dart';
import 'package:hetu_script/grammar/semantic.dart';

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

    void moveNext(String char, {bool handleNewLine = true}) {
      column += char.length;
      pos += char.length;
      if (handleNewLine) {
        if (char == kNewLine) {
          ++line;
          handleEndOfLine(pos);
        }
      }
    }

    final buffer = StringBuffer();

    void addToken() {
      if (buffer.isNotEmpty) {
        final lexeme = buffer.toString();
        currentLineOfTokens
            .add(Token(lexeme, line, column, pos, buffer.length));
        buffer.clear();
      }
    }

    while (iter.moveNext()) {
      final current = iter.current;
      final currentString = iter.current + iter.stringAfter;
      if (current.isNotBlank) {
        if (currentString.startsWith(lexicon.singleLineCommentStart)) {
          do {
            final current2 = iter.current;
            if (current2 == kNewLine) {
              break;
            } else {
              buffer.write(current2);
            }
            moveNext(current2);
          } while (iter.moveNext());
          addToken();
        } else if (currentString.startsWith(lexicon.multiLineCommentStart)) {
          do {
            final current2 = iter.current;
            final currentString2 = current2 + iter.stringAfter;
            if (currentString2.startsWith(lexicon.multiLineCommentEnd)) {
              for (var i = 0; i < lexicon.multiLineCommentEnd.length; ++i) {
                iter.moveNext();
              }
              buffer.write(lexicon.multiLineCommentEnd);
              moveNext(lexicon.multiLineCommentEnd);
              break;
            } else {
              buffer.write(current2);
              moveNext(current2, handleNewLine: false);
            }
          } while (iter.moveNext());
          addToken();
        } else {
          do {
            final current2 = iter.current;
            final lastChar = iter.charactersBefore.isNotEmpty
                ? iter.charactersBefore.last
                : '';
            if (current2.isBlank) {
              addToken();
            } else if (lexicon.singleCharacterPuncuations.contains(current2)) {
              final concact = lastChar + current2;
              if (lexicon.doubleCharacterPuncuations.contains(concact)) {
                buffer.write(current2);
                addToken();
              } else {
                addToken();
                buffer.write(current2);
              }
            } else {
              if (lexicon.singleCharacterPuncuations.contains(lastChar)) {
                addToken();
              }
              buffer.write(current2);
            }
            moveNext(current2);
          } while (iter.moveNext());
          addToken();
        }
      }
      moveNext(current);
    }

    if (currentLineOfTokens.isNotEmpty) {
      handleEndOfLine(currentLineOfTokens.last.end);
    }

    if (tokens.isEmpty) {
      tokens.add(TokenEmptyLine(line, column, pos));
    }

    return tokens;
  }
}
