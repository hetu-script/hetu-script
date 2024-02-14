// import '../source/source.dart';
import '../locale/locale.dart';

import '../error/error.dart';
// import '../error/error_handler.dart';
import 'token.dart';

/// Mixin for handling a token list.
mixin TokenReader {
  /// The file current under processing, used in error message.
  String? currrentFileName;

  int line = 0;
  int column = 0;

  List<HTError> errors = [];

  /// Get current token.
  late Token curTok;

  late Token firstTok;

  late Token endOfFile;

  /// Set current tokens.
  void setTokens({required Token token, int? line, int? column}) {
    curTok = firstTok = token;
    this.line = line ?? 0;
    this.column = column ?? 0;

    Token cur = token;
    while (cur.next != null) {
      cur = cur.next!;
    }
    endOfFile = cur;
  }

  /// Get a token at a relative [distance] from current position.
  Token peek(int distance) {
    Token? result = curTok;
    for (var i = distance; i != 0; i.sign > 0 ? --i : ++i) {
      result = i.sign > 0 ? result?.next : result?.previous;
    }

    return result ?? endOfFile;
  }

  /// Search for parentheses end that can close the current one, return the token next to it.
  Token seekGroupClosing(Map<String, String> groupClosings) {
    var current = curTok;
    final List<String> closings = [];
    var distance = 0;
    var depth = 0;

    do {
      current = peek(distance);
      ++distance;
      if (groupClosings.containsKey(current.lexeme)) {
        closings.add(groupClosings[current.lexeme]!);
        ++depth;
      } else if (closings.isNotEmpty && (current.lexeme == closings.last)) {
        closings.removeLast();
        --depth;
      }
    } while (depth > 0 && current.lexeme != Token.endOfFile);

    return peek(distance);
  }

  /// Search for a token type, return the token next to it.
  Token seek(String type) {
    late Token current;
    var distance = 0;
    do {
      current = peek(distance);
      ++distance;
    } while (current.lexeme != type && curTok.lexeme != Token.endOfFile);
    return peek(distance);
  }

  /// Check current token and some tokens after it to see if the [types] match,
  /// return a boolean result.
  /// If [consume] is true, will advance.
  bool expect(List<String> lexemes, {bool consume = false}) {
    for (var i = 0; i < lexemes.length; ++i) {
      if (peek(i).lexeme != lexemes[i]) {
        return false;
      }
    }
    if (consume) {
      advance(lexemes.length);
    }
    return true;
  }

  /// If the current token is an identifier, advance 1
  /// and return the original token. If not, generate an error.
  TokenIdentifier matchId() {
    if (curTok is TokenIdentifier) {
      return advance() as TokenIdentifier;
    } else {
      final err = HTError.unexpectedToken(
        HTLocale.current.identifier,
        curTok.lexeme,
        filename: currrentFileName,
        line: curTok.line,
        column: curTok.column,
        offset: curTok.offset,
        length: curTok.length,
      );
      errors.add(err);
      final idTok = advance();
      return TokenIdentifier(
        lexeme: idTok.lexeme,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
        previous: idTok.previous,
        next: idTok.next,
      );
    }
  }

  /// If the current token is an identifier, advance 1
  /// and return the original token. If not, generate an error.
  /// Note this only accept string literal but not string interpolation.
  TokenStringLiteral matchString() {
    if (curTok is TokenStringLiteral) {
      return advance() as TokenStringLiteral;
    } else {
      final err = HTError.unexpectedToken(
        HTLocale.current.literalString,
        curTok.lexeme,
        filename: currrentFileName,
        line: curTok.line,
        column: curTok.column,
        offset: curTok.offset,
        length: curTok.length,
      );
      errors.add(err);
      final idTok = advance();
      return TokenStringLiteral(
        lexeme: idTok.lexeme,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
        previous: idTok.previous,
        next: idTok.next,
        startMark: '"',
        endMark: '"',
      );
    }
  }

  /// If the token lexeme the [lexeme] provided, advance 1
  /// and return the original token. If not, generate an error.
  Token match(String lexeme) {
    if (curTok.lexeme != lexeme) {
      final err = HTError.unexpectedToken(lexeme, curTok.lexeme,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    }

    return advance();
  }

  /// same with [match], with plural types provided.
  Token match2(Set<String> lexemes) {
    if (!lexemes.contains(curTok.lexeme)) {
      final err = HTError.unexpectedToken(lexemes.toString(), curTok.lexeme,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    }

    return advance();
  }

  /// Advance till reach [distance], return the token at original position.
  Token advance([int distance = 1]) {
    final previous = curTok;
    for (var i = distance; i > 0; --i) {
      curTok = curTok.next ?? endOfFile;
      line = curTok.line;
      column = curTok.column;
    }
    return previous;
  }
}
