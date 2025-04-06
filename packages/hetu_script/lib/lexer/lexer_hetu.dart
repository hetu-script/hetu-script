import 'package:characters/characters.dart';

import '../parser/token.dart';
import 'lexer.dart';

/// Utility methods on String to check whether it's empty,
/// i.e. contains only white space characters.
extension on String {
  bool get isBlank => isEmpty || trim() == '';
}

const _kNewLine = '\n';
const _kWindowsNewLine = '\r\n';

class HTLexerHetu extends HTLexer {
  late final RegExp _identifierStartRegExp;
  late final RegExp _identifierRegExp;
  late final RegExp _digitRegExp;
  late final RegExp _hexDigitRegExp;

  HTLexerHetu({super.lexicon}) {
    _identifierStartRegExp =
        RegExp(lexicon.identifierStartPattern, unicode: true);
    _identifierRegExp = RegExp(lexicon.identifierPattern, unicode: true);
    _digitRegExp = RegExp(lexicon.digitPattern, unicode: true);
    _hexDigitRegExp = RegExp(lexicon.hexDigitPattern, unicode: true);
  }

  @override
  Token lex(
    String content, {
    int line = 1,
    int column = 1,
    int offset = 0,
  }) {
    Token? firstToken;
    Token? lastToken;
    Token? firstTokenOfCurrentLine;
    Token? lastTokenOfCurrentLine;

    final characters = content.characters.toList();
    int iter = -1;
    String currentCharacter() {
      if (iter < characters.length) {
        return characters[iter];
      } else {
        return '';
      }
    }

    String currentString() {
      if (iter < characters.length) {
        return characters.sublist(iter).join();
      } else {
        return '';
      }
    }

    bool hasAfterString() {
      return iter + 1 < characters.length;
    }

    String afterString() {
      if (iter + 1 < characters.length) {
        return characters.sublist(iter + 1).join();
      } else {
        return '';
      }
    }

    final buffer = StringBuffer();

    void addToken(Token token) {
      firstToken ??= token;
      firstTokenOfCurrentLine ??= token;
      lastTokenOfCurrentLine?.next = token;
      token.previous = lastTokenOfCurrentLine;
      lastTokenOfCurrentLine = token;
    }

    void handleEndOfLine() {
      if (firstTokenOfCurrentLine != null) {
        if (lexicon.autoEndOfStatementMarkInsertionBeforeLineStart
            .contains(firstTokenOfCurrentLine!.lexeme)) {
          /// Add end of statement mark before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the previous line does not ends with an unfinished token.
          if (lastToken != null) {
            if (!lexicon.unfinishedTokens.contains(lastToken!.lexeme)) {
              final token = Token(
                  lexeme: lexicon.endOfStatementMark,
                  line: line,
                  column: lastToken!.end,
                  offset: firstTokenOfCurrentLine!.offset +
                      firstTokenOfCurrentLine!.length);

              token.next = firstTokenOfCurrentLine;
              firstTokenOfCurrentLine!.previous = token;
              firstTokenOfCurrentLine = token;
            }
          }
        } else if (lastTokenOfCurrentLine != null &&
            lastTokenOfCurrentLine!.lexeme == lexicon.kReturn) {
          final token = Token(
              lexeme: lexicon.endOfStatementMark,
              line: line,
              column: 1,
              offset: lastTokenOfCurrentLine!.offset +
                  lastTokenOfCurrentLine!.length);
          addToken(token);
        }
      } else {
        firstTokenOfCurrentLine = lastTokenOfCurrentLine = TokenEmptyLine(
          line: line,
          column: column,
          offset: offset,
        );
      }
      assert(firstTokenOfCurrentLine != null);
      if (lastToken != null) {
        lastToken!.next = firstTokenOfCurrentLine;
        firstTokenOfCurrentLine!.previous = lastTokenOfCurrentLine;
      }
      lastToken = lastTokenOfCurrentLine;
      firstTokenOfCurrentLine = null;
      lastTokenOfCurrentLine = null;
    }

    void handleLineInfo(String char, {bool handleNewLine = true}) {
      column += char.length;
      offset += char.length;
      if (char == _kNewLine || char == _kWindowsNewLine) {
        ++line;
        column = 1;
        if (handleNewLine) {
          handleEndOfLine();
        }
      }
    }

    String handleStringInterpolation() {
      buffer.write(lexicon.stringInterpolationStart);
      for (var i = 0; i < lexicon.stringInterpolationStart.length - 1; ++i) {
        ++iter;
      }
      // get the inner string within the interpolation marker.
      final buffer2 = StringBuffer();
      while (iter < characters.length) {
        ++iter;
        final character = currentCharacter();
        buffer.write(character);
        if (character == lexicon.stringInterpolationEnd) {
          break;
        } else {
          buffer2.write(character);
        }
      }
      return buffer2.toString();
    }

    void hanldeStringLiteral(String startMark, String endMark) {
      bool escappingCharacter = false;
      List<Token> interpolations = [];
      while (iter < characters.length) {
        ++iter;
        final current = currentCharacter();
        final char2nd =
            (iter + 1 < characters.length) ? characters[iter + 1] : '';
        final concact = current + char2nd;
        if (concact == lexicon.stringInterpolationStart &&
            afterString().contains(lexicon.stringInterpolationEnd)) {
          final inner = handleStringInterpolation();
          final innerOffset = offset +
              startMark.length +
              lexicon.stringInterpolationStart.length;
          final token =
              lex(inner, line: line, column: column, offset: innerOffset);
          interpolations.add(token);
        } else {
          buffer.write(current);
          if (current == lexicon.escapeCharacterStart &&
              escappingCharacter == false) {
            escappingCharacter = true;
          } else if (escappingCharacter) {
            escappingCharacter = false;
          } else if (current == startMark && !escappingCharacter) {
            escappingCharacter = false;
            break;
          }
        }
      }

      final lexeme = buffer.toString();
      buffer.clear();
      Token token;
      if (interpolations.isEmpty) {
        token = TokenStringLiteral(
          lexeme: lexeme,
          line: line,
          column: column,
          offset: offset,
          startMark: startMark,
          endMark: endMark,
        );
      } else {
        token = TokenStringInterpolation(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            startMark: startMark,
            endMark: endMark,
            interpolations: interpolations);
      }
      handleLineInfo(lexeme);
      addToken(token);
    }

    bool isNumber(
        String current, String char2nd, String char3rd, String char4th) {
      final concact12 = '$current$char2nd';
      final concact23 = '$char2nd$char3rd';
      if (current == lexicon.negative) {
        if (char2nd == lexicon.decimalPoint) {
          return _digitRegExp.hasMatch(char3rd);
        } else if (concact23 == lexicon.hexNumberStart) {
          return _hexDigitRegExp.hasMatch(char4th);
        } else {
          return _digitRegExp.hasMatch(char2nd);
        }
      } else if (current == lexicon.decimalPoint) {
        return _digitRegExp.hasMatch(char2nd);
      } else if (concact12 == lexicon.hexNumberStart) {
        return _hexDigitRegExp.hasMatch(char3rd);
      } else {
        return _digitRegExp.hasMatch(current);
      }
    }

    while (iter < characters.length) {
      ++iter;
      String character = currentCharacter();
      if (character.isBlank) {
        handleLineInfo(character);
        continue;
      }
      String current = currentString();
      // single line comment
      if (current.startsWith(lexicon.singleLineCommentStart)) {
        do {
          handleLineInfo(character, handleNewLine: false);
          if (character == _kNewLine || character == _kWindowsNewLine) {
            break;
          } else {
            buffer.write(character);
          }
          ++iter;
          character = currentCharacter();
        } while (iter < characters.length);
        final lexeme = buffer.toString();
        final isDocumentation =
            lexeme.startsWith(lexicon.documentationCommentStart);
        String literal;
        if (isDocumentation) {
          literal = lexeme.substring(3);
        } else {
          literal = lexeme.substring(2);
        }
        literal = literal.trim();
        final token = TokenComment(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            literal: literal,
            isDocumentation: isDocumentation,
            isMultiLine: false,
            isTrailing: lastTokenOfCurrentLine != null ? true : false);
        addToken(token);
        buffer.clear();
      }
      // multiline line comment
      else if (current.startsWith(lexicon.multiLineCommentStart)) {
        do {
          if (current.startsWith(lexicon.multiLineCommentEnd)) {
            for (var i = 0; i < lexicon.multiLineCommentEnd.length - 1; ++i) {
              ++iter;
            }
            buffer.write(lexicon.multiLineCommentEnd);
            handleLineInfo(lexicon.multiLineCommentEnd);
            break;
          } else {
            buffer.write(character);
            handleLineInfo(character, handleNewLine: false);
          }
          ++iter;
          character = currentCharacter();
        } while (iter < characters.length);
        final lexeme = buffer.toString();
        String literal;
        literal = lexeme.substring(2, lexeme.length - 2);
        final token = TokenComment(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            literal: literal,
            isMultiLine: true,
            isTrailing: lastTokenOfCurrentLine != null ? true : false);
        addToken(token);
        buffer.clear();
      } else {
        final char2nd =
            (iter + 1 < characters.length) ? characters[iter + 1] : '';
        final char3rd =
            (iter + 2 < characters.length) ? characters[iter + 2] : '';
        final char4th =
            (iter + 3 < characters.length) ? characters[iter + 3] : '';
        final concact12 = character + char2nd;
        final concact123 = character + char2nd + char3rd;
        // final concact23 = char2nd + char3rd;
        // 3 characters punctucation token
        if (lexicon.punctuations.contains(concact123)) {
          for (var i = 0; i < concact123.length - 1; ++i) {
            ++iter;
          }
          final token = Token(
              lexeme: concact123, line: line, column: column, offset: offset);
          handleLineInfo(concact123);
          addToken(token);
          buffer.clear();
        }
        // 2 characters punctucation token
        else if (lexicon.punctuations.contains(concact12)) {
          for (var i = 0; i < concact12.length - 1; ++i) {
            ++iter;
          }
          final token = Token(
              lexeme: concact12, line: line, column: column, offset: offset);
          handleLineInfo(concact12);
          addToken(token);
          buffer.clear();
        }
        // number literal
        else if (isNumber(character, char2nd, char3rd, char4th)) {
          bool isHex = false;
          if (character == lexicon.negative) {
            buffer.write(character);
            ++iter;
            character = currentCharacter();
          }
          final char2nd =
              (iter + 1 < characters.length) ? characters[iter + 1] : '';
          final concact = character + char2nd;
          if (concact == lexicon.hexNumberStart) {
            isHex = true;
            buffer.write(concact);
            ++iter;
            ++iter;
            character = currentCharacter();
          }
          if (!isHex) {
            bool hasDecimalPoint = character == lexicon.decimalPoint;
            buffer.write(character);
            while (hasAfterString()) {
              final char2nd =
                  (iter + 1 < characters.length) ? characters[iter + 1] : '';
              final char3rd =
                  (iter + 2 < characters.length) ? characters[iter + 2] : '';
              if (char2nd == lexicon.decimalPoint) {
                if (!hasDecimalPoint && _digitRegExp.hasMatch(char3rd)) {
                  hasDecimalPoint = true;
                  buffer.write(char2nd);
                  ++iter;
                } else {
                  break;
                }
              } else if (_digitRegExp.hasMatch(char2nd)) {
                buffer.write(char2nd);
                ++iter;
              } else {
                break;
              }
            }
            final lexeme = buffer.toString();
            Token token;
            if (hasDecimalPoint) {
              final n = double.parse(lexeme);
              token = TokenFloatLiteral(
                  lexeme: lexeme,
                  line: line,
                  column: column,
                  offset: offset,
                  literal: n);
            } else {
              final n = int.parse(lexeme);
              token = TokenIntegerLiteral(
                  lexeme: lexeme,
                  line: line,
                  column: column,
                  offset: offset,
                  literal: n);
            }
            handleLineInfo(lexeme);
            addToken(token);
          } else {
            while (hasAfterString()) {
              character = currentCharacter();
              if (_hexDigitRegExp.hasMatch(character)) {
                buffer.write(character);
                ++iter;
              } else {
                break;
              }
            }
            final lexeme = buffer.toString();
            final n = int.parse(lexeme);
            final token = TokenIntegerLiteral(
                lexeme: lexeme,
                line: line,
                column: column,
                offset: offset,
                literal: n);
            handleLineInfo(lexeme);
            addToken(token);
          }
          buffer.clear();
        }
        // punctuation token
        else if (lexicon.punctuations.contains(character)) {
          // string literal
          if (character == lexicon.stringStart1) {
            buffer.write(character);
            hanldeStringLiteral(lexicon.stringStart1, lexicon.stringEnd1);
          } else if (character == lexicon.stringStart2) {
            buffer.write(character);
            hanldeStringLiteral(lexicon.stringStart2, lexicon.stringEnd2);
          }
          // marked identifier
          else if (character == lexicon.identifierStart) {
            buffer.write(character);
            while (iter < characters.length) {
              ++iter;
              character = currentCharacter();
              buffer.write(character);
              if (character == lexicon.identifierEnd) {
                break;
              }
            }
            final lexeme = buffer.toString();
            final token = TokenIdentifier(
                lexeme: lexeme,
                line: line,
                column: column,
                offset: offset,
                isMarked: true);
            handleLineInfo(lexeme);
            addToken(token);
            buffer.clear();
          }
          // normal punctuation
          else {
            buffer.write(character);
            final token = Token(
                lexeme: character, line: line, column: column, offset: offset);
            handleLineInfo(character);
            addToken(token);
            buffer.clear();
          }
        }
        // keyword & normal identifier token
        else if (_identifierStartRegExp.hasMatch(character)) {
          buffer.write(character);
          while (hasAfterString()) {
            final char2nd = characters[iter + 1];
            if (_identifierRegExp.hasMatch(char2nd)) {
              buffer.write(char2nd);
              ++iter;
            } else {
              break;
            }
          }
          final lexeme = buffer.toString();
          Token token;
          if (lexicon.keywords.contains(lexeme)) {
            token = Token(
                lexeme: lexeme,
                line: line,
                column: column,
                offset: offset,
                isKeyword: true);
          } else if (lexeme == lexicon.kTrue) {
            token = TokenBooleanLiteral(
                lexeme: lexeme,
                line: line,
                column: column,
                offset: offset,
                literal: true);
          } else if (lexeme == lexicon.kFalse) {
            token = TokenBooleanLiteral(
                lexeme: lexeme,
                line: line,
                column: column,
                offset: offset,
                literal: false);
          } else {
            token = TokenIdentifier(
                lexeme: lexeme, line: line, column: column, offset: offset);
          }
          handleLineInfo(lexeme);
          addToken(token);
          buffer.clear();
        }
      }
    }

    if (lastTokenOfCurrentLine != null) {
      handleEndOfLine();
    }

    final endOfFile = Token(
        lexeme: Token.endOfFile,
        line: (lastToken?.line ?? 0) + 1,
        column: 0,
        offset: (lastToken?.offset ?? 0) + 1);

    if (lastToken != null) {
      lastToken!.next = endOfFile;
      endOfFile.previous = lastToken;
    } else {
      firstToken = endOfFile;
    }

    return firstToken!;
  }
}
