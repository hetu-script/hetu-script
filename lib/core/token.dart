import '../grammar/semantic.dart';

class Token {
  final String lexeme;

  final int line;
  final int column;

  String get type => lexeme;
  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  Token(this.lexeme, this.line, this.column);
}

class TokenEmptyLine extends Token {
  @override
  String get type => SemanticType.emptyLine;

  TokenEmptyLine(int line, int column) : super('', line, column);
}

class TokenIdentifier extends Token {
  @override
  String get type => SemanticType.identifier;

  TokenIdentifier(String lexeme, int line, int column)
      : super(lexeme, line, column);
}

class TokenBooleanLiteral extends Token {
  @override
  final bool literal;

  @override
  String get type => SemanticType.literalBoolean;

  TokenBooleanLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenIntLiteral extends Token {
  @override
  final int literal;

  @override
  String get type => SemanticType.literalInteger;

  TokenIntLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenFloatLiteral extends Token {
  @override
  final double literal;

  @override
  String get type => SemanticType.literalFloat;

  TokenFloatLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.literalString;

  TokenStringLiteral(this.literal, int line, int column)
      : super(literal, line, column);
}

class TokenSingleLineComment extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.singleLineComment;

  TokenSingleLineComment(this.literal, int line, int column)
      : super(literal, line, column);
}

class TokenMultiLineComment extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.multiLineComment;

  TokenMultiLineComment(this.literal, int line, int column)
      : super(literal, line, column);
}
