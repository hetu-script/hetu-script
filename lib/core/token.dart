import '../grammar/semantic.dart';

class Token {
  final String lexeme;

  final int line;

  final int column;

  String get type => lexeme;

  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  const Token(this.lexeme, this.line, this.column);
}

class TokenEmptyLine extends Token {
  @override
  String get type => SemanticType.emptyLine;

  const TokenEmptyLine(int line, int column) : super('', line, column);
}

class TokenIdentifier extends Token {
  @override
  String get type => SemanticType.identifier;

  const TokenIdentifier(String lexeme, int line, int column)
      : super(lexeme, line, column);
}

class TokenBooleanLiteral extends Token {
  @override
  String get type => SemanticType.literalBoolean;

  @override
  final bool literal;

  const TokenBooleanLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenIntLiteral extends Token {
  @override
  String get type => SemanticType.literalInteger;

  @override
  final int literal;

  const TokenIntLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenFloatLiteral extends Token {
  @override
  String get type => SemanticType.literalFloat;

  @override
  final double literal;

  const TokenFloatLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenStringLiteral extends Token {
  @override
  String get type => SemanticType.literalString;

  @override
  final String literal;

  final String quotationLeft;

  final String quotationRight;

  const TokenStringLiteral(this.literal, this.quotationLeft,
      this.quotationRight, int line, int column)
      : super(literal, line, column);
}

class TokenStringInterpolation extends TokenStringLiteral {
  @override
  String get type => SemanticType.stringInterpolation;

  final List<List<Token>> interpolations;

  const TokenStringInterpolation(String literal, String quotationLeft,
      String quotationRight, this.interpolations, int line, int column)
      : super(literal, quotationLeft, quotationRight, line, column);
}

class TokenSingleLineComment extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.singleLineComment;

  const TokenSingleLineComment(this.literal, int line, int column)
      : super(literal, line, column);
}

class TokenMultiLineComment extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.multiLineComment;

  const TokenMultiLineComment(this.literal, int line, int column)
      : super(literal, line, column);
}
