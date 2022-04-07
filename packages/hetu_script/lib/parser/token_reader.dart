// import '../source/source.dart';
import '../error/error.dart';
// import '../error/error_handler.dart';
import '../lexicon/lexicon.dart';
import '../grammar/constant.dart';
import 'token.dart';

/// Abstract interface for handling a token list.
abstract class TokenReader {
  /// The file current under processing, used in error message.
  String? currrentFileName;

  int line = 0;
  int column = 0;

  List<HTError>? errors;

  /// Get current token.
  late Token curTok;

  late Token firstTok;

  late Token endOfFile;

  // Token get curTok => peek(0);

  void setTokens({required Token token, int? line, int? column}) {
    curTok = firstTok = token;
    // _tokens.clear();
    // _tokens.addAll(tokens);
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

  /// Search for parentheses right token that can closing the current one, return the token next to it.
  Token seekGroupClosing() {
    var current = curTok;
    late String closing;
    var distance = 0;
    var depth = 0;
    if (current.type == HTLexicon.groupExprStart) {
      closing = HTLexicon.groupExprEnd;
    } else if (current.type == HTLexicon.listStart) {
      closing = HTLexicon.listEnd;
    } else if (current.type == HTLexicon.functionBlockStart) {
      closing = HTLexicon.functionBlockEnd;
    } else if (current.type == HTLexicon.typeParameterStart) {
      closing = HTLexicon.typeParameterEnd;
    } else {
      return current;
    }
    void forward() {
      current = peek(distance);
    }

    do {
      forward();
      ++distance;
      if (current.type == HTLexicon.groupExprStart) {
        ++depth;
      } else if (depth > 0 && current.type == closing) {
        --depth;
      }
    } while ((depth > 0 || current.type != closing) &&
        current.type != Semantic.endOfFile);
    return peek(distance);
  }

  /// Search for a token type, return the token next to it.
  Token seek(String type) {
    late Token current;
    var distance = 0;
    do {
      current = peek(distance);
      ++distance;
    } while (current.type != type && curTok.type != Semantic.endOfFile);
    return peek(distance);
  }

  /// Check current token and some tokens after it to see if the [types] match,
  /// return a boolean result.
  /// If [consume] is true, will advance.
  bool expect(List<String> types, {bool consume = false}) {
    for (var i = 0; i < types.length; ++i) {
      if (peek(i).type != types[i]) {
        return false;
      }
    }
    if (consume) {
      advance(types.length);
    }
    return true;
  }

  /// If the token match the [type] provided, advance 1
  /// and return the original token. If not, generate an error.
  Token match(String type) {
    if (curTok.type != type) {
      final err = HTError.unexpected(type, curTok.lexeme,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors?.add(err);
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
