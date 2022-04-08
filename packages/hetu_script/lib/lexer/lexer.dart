import 'package:characters/characters.dart';

import '../parser/token.dart';
import 'lexicon.dart';
import '../lexer/lexicon_default_impl.dart';
import '../comment/comment.dart' show CommentType;
import '../grammar/constant.dart';

extension on String {
  /// Whether this string is empty or contains only white space characters.
  bool get isBlank => isEmpty || trim() == '';
  bool get isNotBlank => !isBlank;
}

const _kNewLine = '\n';
const _kWindowsNewLine = '\r\n';

class HTLexer {
  final HTLexicon lexicon;

  late final RegExp _identifierStartRegExp;
  late final RegExp _identifierRegExp;
  late final RegExp _numberStartRegExp;
  late final RegExp _numberRegExp;
  late final RegExp _hexNumberRegExp;

  HTLexer({HTLexicon? lexicon}) : lexicon = lexicon ?? HTDefaultLexicon() {
    _identifierStartRegExp =
        RegExp(this.lexicon.identifierStartPattern, unicode: true);
    _identifierRegExp = RegExp(this.lexicon.identifierPattern, unicode: true);
    _numberStartRegExp = RegExp(this.lexicon.numberStartPattern);
    _numberRegExp = RegExp(this.lexicon.numberPattern);
    _hexNumberRegExp = RegExp(this.lexicon.hexNumberPattern);
  }

  /// Scan a string content and convert it into a linked list of tokens.
  /// The last element in the list will always be a end of file token.
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

    void handleEndOfLine([int? lineEnd]) {
      if (firstTokenOfCurrentLine != null) {
        if (lexicon.autoSemicolonInsertAtStart
            .contains(firstTokenOfCurrentLine!.type)) {
          /// Add semicolon before a newline if the new line starting with '{, [, (, +, -' tokens
          /// and the last line does not ends with an unfinished token.
          if (lastToken != null) {
            if (!lexicon.unfinishedTokens.contains(lastToken!.type)) {
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
            lastTokenOfCurrentLine!.type == lexicon.kReturn) {
          final token = Token(
              lexeme: lexicon.endOfStatementMark,
              line: line,
              column: 1,
              offset: lastTokenOfCurrentLine!.offset +
                  lastTokenOfCurrentLine!.length);
          addToken(token);
        }
      } else {
        firstTokenOfCurrentLine = lastTokenOfCurrentLine =
            TokenEmptyLine(line: line, column: column, offset: offset);
      }
      assert(firstTokenOfCurrentLine != null);
      if (lastToken != null) {
        lastToken!.next = firstTokenOfCurrentLine;
        firstTokenOfCurrentLine!.previous = lastTokenOfCurrentLine;
      }
      lastToken = lastTokenOfCurrentLine;
      firstTokenOfCurrentLine = null;
      lastTokenOfCurrentLine = null;
      ++line;
      // empty line counts as a character
      if (lineEnd == null) {
        offset += 1;
      } else {
        offset = lineEnd + 1;
      }
    }

    void handleLineInfo(String char, {bool handleNewLine = true}) {
      column += char.length;
      offset += char.length;
      if (handleNewLine) {
        if (char == _kNewLine || char == _kWindowsNewLine) {
          column = 1;
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
        handleLineInfo(current, handleNewLine: false);
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
            if (current == _kNewLine || current == _kWindowsNewLine) {
              break;
            } else {
              buffer.write(current);
            }
          } while (iter.moveNext());
          final lexeme = buffer.toString();
          final token = TokenComment(
              lexeme: lexeme,
              line: line,
              column: column,
              offset: offset,
              commentType:
                  currentString.startsWith(lexicon.documentationCommentStart)
                      ? CommentType.documentation
                      : CommentType.singleLine,
              isTrailing: lastTokenOfCurrentLine != null ? true : false);
          handleLineInfo(lexeme);
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
          final token = TokenComment(
              lexeme: lexeme,
              line: line,
              column: column,
              offset: offset,
              commentType: CommentType.multiLine,
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
              bool escappingCharacter = false;
              buffer.write(current);
              List<Token> interpolations = [];
              while (iter.moveNext()) {
                current = iter.current;
                final charNext = iter.charactersAfter.isNotEmpty
                    ? iter.charactersAfter.first
                    : '';
                final concact = current + charNext;
                if (concact == lexicon.stringInterpolationStart &&
                    iter.charactersAfter
                        .contains(lexicon.stringInterpolationEnd)) {
                  final inner = handleStringInterpolation();
                  final token =
                      lex(inner, line: line, column: column, offset: offset);
                  interpolations.add(token);
                } else {
                  buffer.write(current);
                  if (current == lexicon.escapeCharacterStart &&
                      escappingCharacter == false) {
                    escappingCharacter = true;
                  } else if (escappingCharacter) {
                    escappingCharacter = false;
                  } else if (current == lexicon.stringEnd1 &&
                      !escappingCharacter) {
                    escappingCharacter = false;
                    break;
                  }
                }
              }
              final literal = buffer.toString();
              final lexeme = literal.substring(1, literal.length - 1);
              buffer.clear();
              Token token;
              if (interpolations.isEmpty) {
                token = TokenStringLiteral(
                    lexeme: lexeme,
                    line: line,
                    column: column,
                    offset: offset,
                    startMark: lexicon.stringStart1,
                    endMark: lexicon.stringEnd1);
              } else {
                token = TokenStringInterpolation(
                    lexeme: lexeme,
                    line: line,
                    column: column,
                    offset: offset,
                    startMark: lexicon.stringStart1,
                    endMark: lexicon.stringEnd1,
                    interpolations: interpolations);
              }
              handleLineInfo(lexeme);
              addToken(token);
            } else if (current == lexicon.stringStart2) {
              bool escappingCharacter = false;
              buffer.write(current);
              List<Token> interpolations = [];
              while (iter.moveNext()) {
                current = iter.current;
                final charNext = iter.charactersAfter.isNotEmpty
                    ? iter.charactersAfter.first
                    : '';
                final concact = current + charNext;
                if (concact == lexicon.stringInterpolationStart &&
                    iter.charactersAfter
                        .contains(lexicon.stringInterpolationEnd)) {
                  final inner = handleStringInterpolation();
                  final token =
                      lex(inner, line: line, column: column, offset: offset);
                  interpolations.add(token);
                } else {
                  buffer.write(current);
                  if (current == lexicon.escapeCharacterStart &&
                      escappingCharacter == false) {
                    escappingCharacter = true;
                  } else if (escappingCharacter) {
                    escappingCharacter = false;
                  } else if (current == lexicon.stringEnd2 &&
                      !escappingCharacter) {
                    escappingCharacter = false;
                    break;
                  }
                }
              }
              final literal = buffer.toString();
              final lexeme = literal.substring(1, literal.length - 1);
              buffer.clear();
              Token token;
              if (interpolations.isEmpty) {
                token = TokenStringLiteral(
                    lexeme: lexeme,
                    line: line,
                    column: column,
                    offset: offset,
                    startMark: lexicon.stringStart2,
                    endMark: lexicon.stringEnd2);
              } else {
                token = TokenStringInterpolation(
                    lexeme: lexeme,
                    line: line,
                    column: column,
                    offset: offset,
                    startMark: lexicon.stringStart2,
                    endMark: lexicon.stringEnd2,
                    interpolations: interpolations);
              }
              handleLineInfo(lexeme);
              addToken(token);
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
                if (_numberRegExp.hasMatch(charNext)) {
                  if (charNext == lexicon.decimalPoint) {
                    if (!hasDecimalPoint) {
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
                token = TokenIntLiteral(
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
              final token = TokenIntLiteral(
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
      handleEndOfLine(lastTokenOfCurrentLine!.end);
    }

    final endOfFile = Token(
        lexeme: Semantic.endOfFile,
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
