import 'package:characters/characters.dart';

import '../parser/token.dart';
import 'lexer.dart';

/// Utility methods on String to check whether it's empty,
/// i.e. contains only white space characters.
extension on String {
  bool get isBlank => isEmpty || trim() == '';
  bool get isNotBlank => !isBlank;
}

const _kNewLine = '\n';
const _kWindowsNewLine = '\r\n';

class HTLexerHetu extends HTLexer {
  late final RegExp _identifierStartRegExp;
  late final RegExp _identifierRegExp;
  late final RegExp _numberStartRegExp;
  late final RegExp _numberRegExp;
  late final RegExp _digitRegExp;
  late final RegExp _hexNumberRegExp;

  HTLexerHetu({super.lexicon}) {
    _identifierStartRegExp =
        RegExp(lexicon.identifierStartPattern, unicode: true);
    _identifierRegExp = RegExp(lexicon.identifierPattern, unicode: true);
    _numberStartRegExp = RegExp(lexicon.numberStartPattern);
    _numberRegExp = RegExp(lexicon.numberPattern);
    _digitRegExp = RegExp(lexicon.digitPattern);
    _hexNumberRegExp = RegExp(lexicon.hexNumberPattern);
  }

  @override
  Token lex(String content, {int line = 1, int column = 1, int offset = 0}) {
    final iter = content.characters.iterator;
    Token? firstToken;
    Token? lastToken;
    Token? firstTokenOfCurrentLine;
    Token? lastTokenOfCurrentLine;

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
        if (current == lexicon.stringInterpolationEnd) {
          break;
        } else {
          buffer2.write(current);
        }
      }
      return buffer2.toString();
    }

    void hanldeStringLiteral(String startMark, String endMark) {
      bool escappingCharacter = false;
      List<Token> interpolations = [];
      while (iter.moveNext()) {
        current = iter.current;
        final charNext =
            iter.charactersAfter.isNotEmpty ? iter.charactersAfter.first : '';
        final concact = current + charNext;
        if (concact == lexicon.stringInterpolationStart &&
            iter.charactersAfter.contains(lexicon.stringInterpolationEnd)) {
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

    while (iter.moveNext()) {
      current = iter.current;
      var currentString = iter.current + iter.stringAfter;
      if (current.isNotBlank) {
        // single line comment
        if (currentString.startsWith(lexicon.singleLineCommentStart)) {
          do {
            current = iter.current;
            handleLineInfo(current, handleNewLine: false);
            if (current == _kNewLine || current == _kWindowsNewLine) {
              break;
            } else {
              buffer.write(current);
            }
          } while (iter.moveNext());
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
        else if (currentString.startsWith(lexicon.multiLineCommentStart)) {
          do {
            current = iter.current;
            currentString = current + iter.stringAfter;
            if (currentString.startsWith(lexicon.multiLineCommentEnd)) {
              for (var i = 0; i < lexicon.multiLineCommentEnd.length - 1; ++i) {
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
          final charNext =
              iter.charactersAfter.isNotEmpty ? iter.charactersAfter.first : '';
          final char3rd = iter.charactersAfter.length > 1
              ? iter.charactersAfter.elementAt(1)
              : '';
          final concact2 = current + charNext;
          final concact3 = current + charNext + char3rd;
          // 3 characters punctucation token
          if (lexicon.punctuations.contains(concact3)) {
            for (var i = 0; i < concact3.length - 1; ++i) {
              iter.moveNext();
            }
            final token = Token(
                lexeme: concact3, line: line, column: column, offset: offset);
            handleLineInfo(concact3);
            addToken(token);
            buffer.clear();
          }
          // 2 characters punctucation token
          else if (lexicon.punctuations.contains(concact2)) {
            for (var i = 0; i < concact2.length - 1; ++i) {
              iter.moveNext();
            }
            final token = Token(
                lexeme: concact2, line: line, column: column, offset: offset);
            handleLineInfo(concact2);
            addToken(token);
            buffer.clear();
          }
          // punctuation token
          else if (lexicon.punctuations.contains(current)) {
            // string literal
            if (current == lexicon.stringStart1) {
              buffer.write(current);
              hanldeStringLiteral(lexicon.stringStart1, lexicon.stringEnd1);
            } else if (current == lexicon.stringStart2) {
              buffer.write(current);
              hanldeStringLiteral(lexicon.stringStart2, lexicon.stringEnd2);
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
              buffer.write(current);
              final token = Token(
                  lexeme: current, line: line, column: column, offset: offset);
              handleLineInfo(current);
              addToken(token);
              buffer.clear();
            }
          }
          // keyword & normal identifier token
          else if (_identifierStartRegExp.hasMatch(current)) {
            buffer.write(current);
            while (iter.charactersAfter.isNotEmpty) {
              final charNext = iter.charactersAfter.first;
              if (_identifierRegExp.hasMatch(charNext)) {
                buffer.write(charNext);
                iter.moveNext();
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
          // number literal
          else if (_numberStartRegExp.hasMatch(current)) {
            if (!currentString.startsWith(lexicon.hexNumberStart)) {
              buffer.write(current);
              bool hasDecimalPoint = current == lexicon.decimalPoint;
              while (iter.charactersAfter.isNotEmpty) {
                final charNext = iter.charactersAfter.first;
                final char3rd = iter.charactersAfter.length > 1
                    ? iter.charactersAfter.elementAt(1)
                    : '';
                if (_numberRegExp.hasMatch(charNext)) {
                  if (charNext == lexicon.decimalPoint) {
                    if (!hasDecimalPoint && _digitRegExp.hasMatch(char3rd)) {
                      hasDecimalPoint = true;
                    } else {
                      break;
                    }
                  }
                  buffer.write(charNext);
                  iter.moveNext();
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
              buffer.write(lexicon.hexNumberStart);
              for (var i = 0; i < lexicon.hexNumberStart.length - 1; ++i) {
                iter.moveNext();
              }
              while (iter.charactersAfter.isNotEmpty) {
                final charNext = iter.charactersAfter.first;
                if (_hexNumberRegExp.hasMatch(charNext)) {
                  buffer.write(charNext);
                  iter.moveNext();
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
        }
      } else {
        handleLineInfo(current);
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
