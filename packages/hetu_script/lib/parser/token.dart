import '../grammar/constant.dart';
import '../comment/comment.dart' show CommentType;

class Token {
  final String lexeme;

  final int line;

  final int column;

  final int offset;

  int get length => lexeme.length;

  int get end => offset + length;

  String get type => lexeme;

  dynamic get literal => lexeme;

  final bool isKeyword;

  Token? previous;

  Token? next;

  @override
  String toString() => lexeme;

  Token({
    required this.lexeme,
    required this.line,
    required this.column,
    required this.offset,
    this.isKeyword = false,
    this.previous,
    this.next,
  });
}

class TokenEmptyLine extends Token {
  TokenEmptyLine(
      {required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next})
      : super(
            lexeme: Semantic.emptyLine,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenIdentifier extends Token {
  @override
  String get type => Semantic.identifier;

  /// whether this identifier is marked by grave accent marks.
  final bool isMarked;

  TokenIdentifier(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      this.isMarked = false})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenBooleanLiteral extends Token {
  @override
  String get type => Semantic.literalBoolean;

  @override
  final bool literal;

  TokenBooleanLiteral(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required this.literal})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenIntLiteral extends Token {
  @override
  String get type => Semantic.literalInteger;

  @override
  final int literal;

  TokenIntLiteral(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required this.literal})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenFloatLiteral extends Token {
  @override
  String get type => Semantic.literalFloat;

  @override
  final double literal;

  TokenFloatLiteral(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required this.literal})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenStringLiteral extends Token {
  @override
  String get type => Semantic.literalString;

  final String startMark;

  final String endMark;

  TokenStringLiteral(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required this.startMark,
      required this.endMark})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}

class TokenStringInterpolation extends TokenStringLiteral {
  @override
  String get type => Semantic.literalStringInterpolation;

  final List<Token> interpolations;

  TokenStringInterpolation(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required String startMark,
      required String endMark,
      required this.interpolations})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next,
            startMark: startMark,
            endMark: endMark);
}

class TokenComment extends Token {
  @override
  String get type => Semantic.comment;

  final CommentType commentType;

  final bool isTrailing;

  TokenComment(
      {required String lexeme,
      required int line,
      required int column,
      required int offset,
      Token? previous,
      Token? next,
      required this.commentType,
      this.isTrailing = false})
      : super(
            lexeme: lexeme,
            line: line,
            column: column,
            offset: offset,
            previous: previous,
            next: next);
}
