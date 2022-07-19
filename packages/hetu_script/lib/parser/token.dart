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

// class TokenEmptyLine extends Token {
//   TokenEmptyLine(
//       {required super.line,
//       required super.column,
//       required super.offset,
//       super.previous,
//       super.next})
//       : super(lexeme: Semantic.emptyLine);
// }

class TokenIdentifier extends Token {
  @override
  String get type => Semantic.identifier;

  /// whether this identifier is marked by grave accent marks.
  final bool isMarked;

  @override
  final String literal;

  TokenIdentifier(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      this.isMarked = false})
      : literal = isMarked ? lexeme.substring(1, lexeme.length - 1) : lexeme;
}

class TokenBooleanLiteral extends Token {
  @override
  String get type => Semantic.literalBoolean;

  @override
  final bool literal;

  TokenBooleanLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenIntLiteral extends Token {
  @override
  String get type => Semantic.literalInteger;

  @override
  final int literal;

  TokenIntLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenFloatLiteral extends Token {
  @override
  String get type => Semantic.literalFloat;

  @override
  final double literal;

  TokenFloatLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenStringLiteral extends Token {
  @override
  String get type => Semantic.literalString;

  final String _literal;

  @override
  String get literal => _literal;

  final String startMark;

  final String endMark;

  TokenStringLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.startMark,
      required this.endMark})
      : _literal = lexeme.substring(1, lexeme.length - 1);
}

class TokenStringInterpolation extends TokenStringLiteral {
  @override
  String get type => Semantic.literalStringInterpolation;

  final List<Token> interpolations;

  TokenStringInterpolation(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required super.startMark,
      required super.endMark,
      required this.interpolations});
}

class TokenCommentOrEmptyLine extends Token {
  @override
  String get type => Semantic.comment;

  final CommentType commentType;

  final bool isTrailing;

  TokenCommentOrEmptyLine(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.commentType,
      this.isTrailing = false});
}
