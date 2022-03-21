import 'package:characters/characters.dart';

import 'token.dart';
import '../grammar/lexicon2.dart';
import '../grammar/lexicon_impl.dart';
import '../shared/constants.dart' show CommentType;

extension on String {
  /// Whether this string is empty or contains only white space characters.
  bool get isBlank => isEmpty || trim() == '';
  bool get isNotBlank => !isBlank;
}

const _kNewLine = '\n';

class HTLexer {
  final HTLexicon lexicon;

  late final RegExp _identifierStartRegExp;
  late final RegExp _identifierRegExp;
  late final RegExp _numberStartRegExp;
  late final RegExp _numberRegExp;

  HTLexer({HTLexicon? lexicon}) : lexicon = lexicon ?? HTDefaultLexicon() {
    _identifierStartRegExp =
        RegExp(this.lexicon.identifierStartPattern, unicode: true);
    _identifierRegExp = RegExp(this.lexicon.identifierPattern, unicode: true);
    _numberStartRegExp = RegExp(this.lexicon.numberStartPattern);
    _numberRegExp = RegExp(this.lexicon.numberPattern);
  }

  List<Token> lex(String content,
      {int line = 1, int column = 1, int offset = 0}) {
    final tokens = <Token>[];
    final iter = content.characters.iterator;
    final currentLineOfTokens = <Token>[];

    void handleEndOfLine([int? lineLength]) {
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
        tokens.add(TokenEmptyLine(line, column, offset));
      }
      ++line;
      // empty line counts as a character
      if (lineLength == null) {
        offset += 1;
      } else {
        offset = lineLength + 1;
      }
      currentLineOfTokens.clear();
    }

    void handleLineInfo(String char, {bool handleNewLine = true}) {
      column += char.length;
      offset += char.length;
      if (handleNewLine) {
        if (char == _kNewLine) {
          ++line;
          handleEndOfLine(offset);
        }
      }
    }

    final buffer = StringBuffer();
    String current;

    String handleStringInterpolation() {
      buffer.write(lexicon.stringInterpolationStart);
      for (var i = 0; i < lexicon.stringInterpolationStart.length - 1; ++i) {
        iter.moveNext();
      }
      // get the inner string within the interpolation marker.
      final buffer2 = StringBuffer();
      while (iter.moveNext()) {
        current = iter.current;
        buffer.write(current);
        handleLineInfo(current);
        if (current == lexicon.stringInterpolationEnd) {
          break;
        } else {
          buffer2.write(current);
        }
      }
      return buffer2.toString();
    }

    while (iter.moveNext()) {
      current = iter.current;
      var currentString = iter.current + iter.stringAfter;
      if (current.isNotBlank) {
        // single line comment
        if (currentString.startsWith(lexicon.singleLineCommentStart)) {
          do {
            current = iter.current;
            if (current == _kNewLine) {
              break;
            } else {
              buffer.write(current);
            }
          } while (iter.moveNext());
          final lexeme = buffer.toString();
          handleLineInfo(lexeme);
          final token = TokenComment(
              lexeme, line, column, offset, buffer.length,
              commentType:
                  currentString.startsWith(lexicon.documentationCommentStart)
                      ? CommentType.documentation
                      : CommentType.singleLine,
              isTrailing: currentLineOfTokens.isNotEmpty ? true : false);
          currentLineOfTokens.add(token);
          buffer.clear();
        }
        // multiline line comment
        else if (currentString.startsWith(lexicon.multiLineCommentStart)) {
          do {
            current = iter.current;
            currentString = current + iter.stringAfter;
            if (currentString.startsWith(lexicon.multiLineCommentEnd)) {
              for (var i = 0; i < lexicon.multiLineCommentEnd.length; ++i) {
                iter.moveNext();
              }
              buffer.write(lexicon.multiLineCommentEnd);
              handleLineInfo(lexicon.multiLineCommentEnd);
              break;
            } else {
              buffer.write(current);
              handleLineInfo(current, handleNewLine: false);
            }
          } while (iter.moveNext());
          final lexeme = buffer.toString();
          final token = TokenComment(
              lexeme, line, column, offset, buffer.length,
              commentType: CommentType.multiLine,
              isTrailing: currentLineOfTokens.isNotEmpty ? true : false);
          currentLineOfTokens.add(token);
          buffer.clear();
        } else {
          final nextChar =
              iter.charactersAfter.isNotEmpty ? iter.charactersAfter.first : '';
          final concact = current + nextChar;
          // multiple character punctucation token
          if (lexicon.punctuations.contains(concact)) {
            for (var i = 0; i < concact.length; ++i) {
              iter.moveNext();
            }
            handleLineInfo(concact);
            final token = Token(concact, line, column, offset, buffer.length);
            currentLineOfTokens.add(token);
            buffer.clear();
          }
          // punctuation token
          else if (lexicon.punctuations.contains(current)) {
            // string literal
            if (current == lexicon.stringStart1) {
              buffer.write(current);
              List<List<Token>> interpolations = [];
              while (iter.moveNext()) {
                current = iter.current;
                final nextChar = iter.charactersAfter.isNotEmpty
                    ? iter.charactersAfter.first
                    : '';
                final concact = current + nextChar;
                if (concact == lexicon.stringInterpolationStart &&
                    iter.charactersAfter
                        .contains(lexicon.stringInterpolationEnd)) {
                  final inner = handleStringInterpolation();
                  final innerTokens =
                      lex(inner, line: line, column: column, offset: offset);
                  interpolations.add(innerTokens);
                } else {
                  buffer.write(current);
                  if (current == lexicon.stringEnd1) {
                    break;
                  }
                }
              }
              final lexeme = buffer.toString();
              buffer.clear();
              handleLineInfo(lexeme);
              Token token;
              if (interpolations.isEmpty) {
                token = TokenStringLiteral(lexeme, lexicon.stringStart1,
                    lexicon.stringEnd1, line, column, offset, lexeme.length);
              } else {
                token = TokenStringInterpolation(
                    lexeme,
                    lexicon.stringStart1,
                    lexicon.stringEnd1,
                    interpolations,
                    line,
                    column,
                    offset,
                    lexeme.length);
              }
              currentLineOfTokens.add(token);
            } else if (current == lexicon.stringStart2) {
              buffer.write(current);
              List<List<Token>> interpolations = [];
              while (iter.moveNext()) {
                current = iter.current;
                final nextChar = iter.charactersAfter.isNotEmpty
                    ? iter.charactersAfter.first
                    : '';
                final concact = current + nextChar;
                if (concact == lexicon.stringInterpolationStart &&
                    iter.charactersAfter
                        .contains(lexicon.stringInterpolationEnd)) {
                  final inner = handleStringInterpolation();
                  final innerTokens =
                      lex(inner, line: line, column: column, offset: offset);
                  interpolations.add(innerTokens);
                } else {
                  buffer.write(current);
                  if (current == lexicon.stringEnd2) {
                    break;
                  }
                }
              }
              final lexeme = buffer.toString();
              buffer.clear();
              handleLineInfo(lexeme);
              Token token;
              if (interpolations.isEmpty) {
                token = TokenStringLiteral(lexeme, lexicon.stringStart2,
                    lexicon.stringEnd2, line, column, offset, lexeme.length);
              } else {
                token = TokenStringInterpolation(
                    lexeme,
                    lexicon.stringStart2,
                    lexicon.stringEnd2,
                    interpolations,
                    line,
                    column,
                    offset,
                    lexeme.length);
              }
              currentLineOfTokens.add(token);
            }
            // marked identifier
            else if (current == lexicon.identifierStart) {
              buffer.write(current);
              while (iter.moveNext()) {
                current = iter.current;
                buffer.write(current);
                if (current == lexicon.identifierEnd) {
                  break;
                }
              }
              final lexeme = buffer.toString();
              handleLineInfo(lexeme);
              final token = TokenIdentifier(
                  lexeme, line, column, offset, buffer.length,
                  isMarked: true);
              currentLineOfTokens.add(token);
              buffer.clear();
            }
            // normal punctuation
            else {
              buffer.write(concact);
              handleLineInfo(concact);
              final token = Token(current, line, column, offset, buffer.length);
              currentLineOfTokens.add(token);
              buffer.clear();
            }
          }
          // keyword & normal identifier token
          else if (_identifierStartRegExp.hasMatch(current)) {
            buffer.write(current);
            while (iter.charactersAfter.isNotEmpty) {
              final nextChar = iter.charactersAfter.first;
              if (_identifierRegExp.hasMatch(nextChar)) {
                buffer.write(nextChar);
                iter.moveNext();
              } else {
                break;
              }
            }
            final lexeme = buffer.toString();
            handleLineInfo(lexeme);
            Token token;
            if (lexicon.keywords.contains(lexeme)) {
              token = Token(lexeme, line, column, offset, buffer.length,
                  isKeyword: true);
            } else if (lexeme == lexicon.kTrue) {
              token = TokenBooleanLiteral(
                  lexeme, true, line, column, offset, lexeme.length);
            } else if (lexeme == lexicon.kFalse) {
              token = TokenBooleanLiteral(
                  lexeme, false, line, column, offset, lexeme.length);
            } else {
              token =
                  TokenIdentifier(lexeme, line, column, offset, buffer.length);
            }
            currentLineOfTokens.add(token);
            buffer.clear();
          } else if (_numberStartRegExp.hasMatch(current)) {
            bool hasDecimalPoint = current == lexicon.decimalPoint;
            buffer.write(current);
            while (iter.charactersAfter.isNotEmpty) {
              final nextChar = iter.charactersAfter.first;
              if (_numberRegExp.hasMatch(nextChar)) {
                if (nextChar == lexicon.decimalPoint) {
                  if (!hasDecimalPoint) {
                    hasDecimalPoint = true;
                  } else {
                    break;
                  }
                }
                buffer.write(nextChar);
                iter.moveNext();
              } else {
                break;
              }
            }
            final lexeme = buffer.toString();
            handleLineInfo(lexeme);
            Token token;
            if (hasDecimalPoint) {
              final n = double.parse(lexeme);
              token = TokenFloatLiteral(
                  lexeme, n, line, column, offset, buffer.length);
            } else {
              final n = int.parse(lexeme);
              token = TokenIntLiteral(
                  lexeme, n, line, column, offset, buffer.length);
            }
            currentLineOfTokens.add(token);
            buffer.clear();
          }
        }
      }
      handleLineInfo(current);
    }

    if (currentLineOfTokens.isNotEmpty) {
      handleEndOfLine(currentLineOfTokens.last.end);
    }

    if (tokens.isEmpty) {
      tokens.add(TokenEmptyLine(line, column, offset));
    }

    return tokens;
  }
}
