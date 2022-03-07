import '../grammar/semantic.dart';
import '../shared/constants.dart' show CommentType;

class Token {
  final String lexeme;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  String get type => lexeme;

  dynamic get literal => lexeme;

  final bool isKeyword;

  @override
  String toString() => lexeme;

  const Token(this.lexeme, this.line, this.column, this.offset, this.length,
      [this.isKeyword = false]);
}

class TokenEmpty extends Token {
  @override
  String get type => Semantic.empty;

  const TokenEmpty(int line, int column, int offset)
      : super('', line, column, offset, 0);
}

class TokenEmptyLine extends Token {
  @override
  String get type => Semantic.emptyLine;

  const TokenEmptyLine(int line, int column, int offset)
      : super('', line, column, offset, 0);
}

class TokenIdentifier extends Token {
  @override
  String get type => Semantic.identifier;

  const TokenIdentifier(
      String lexeme, int line, int column, int offset, int length)
      : super(lexeme, line, column, offset, length);
}

class TokenBooleanLiteral extends Token {
  @override
  String get type => Semantic.booleanLiteral;

  @override
  final bool literal;

  const TokenBooleanLiteral(
      String lexeme, this.literal, int line, int column, int offset, int length)
      : super(lexeme, line, column, offset, length);
}

class TokenIntLiteral extends Token {
  @override
  String get type => Semantic.integerLiteral;

  @override
  final int literal;

  const TokenIntLiteral(
      String lexeme, this.literal, int line, int column, int offset, int length)
      : super(lexeme, line, column, offset, length);
}

class TokenFloatLiteral extends Token {
  @override
  String get type => Semantic.floatLiteral;

  @override
  final double literal;

  const TokenFloatLiteral(
      String lexeme, this.literal, int line, int column, int offset, int length)
      : super(lexeme, line, column, offset, length);
}

class TokenStringLiteral extends Token {
  @override
  String get type => Semantic.stringLiteral;

  @override
  final String literal;

  final String quotationLeft;

  final String quotationRight;

  const TokenStringLiteral(this.literal, this.quotationLeft,
      this.quotationRight, int line, int column, int offset, int length)
      : super(literal, line, column, offset, length);
}

class TokenStringInterpolation extends TokenStringLiteral {
  @override
  String get type => Semantic.stringInterpolation;

  final List<List<Token>> interpolations;

  const TokenStringInterpolation(
      String literal,
      String quotationLeft,
      String quotationRight,
      this.interpolations,
      int line,
      int column,
      int offset,
      int length)
      : super(literal, quotationLeft, quotationRight, line, column, offset,
            length);
}

class TokenComment extends Token {
  @override
  final String literal;

  @override
  String get type => Semantic.comment;

  final CommentType commentType;

  final bool isTrailing;

  const TokenComment(this.literal, int line, int column, int offset, int length,
      {required this.commentType, this.isTrailing = false})
      : super(literal, line, column, offset, length);
}
