import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';

class Token {
  final String lexeme;

  final String moduleFullName;
  final int line;
  final int column;

  String get type => lexeme;
  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  Token(this.lexeme, this.moduleFullName, this.line, this.column);
}

class TokenIdentifier extends Token {
  @override
  String get type => SemanticType.identifier;

  TokenIdentifier(String lexeme, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  @override
  String get type => lexeme;

  TokenBoolLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenNumberLiteral extends Token {
  @override
  final num literal;

  @override
  String get type => HTLexicon.number;

  TokenNumberLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenIntLiteral extends Token {
  @override
  final int literal;

  @override
  String get type => HTLexicon.integer;

  TokenIntLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenFloatLiteral extends Token {
  @override
  final double literal;

  @override
  String get type => HTLexicon.float;

  TokenFloatLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  String get type => SemanticType.literalString;

  TokenStringLiteral(this.literal, String moduleFullName, int line, int column)
      : super(literal, moduleFullName, line, column);
}

class TokenComment extends Token {
  @override
  final String literal;

  final bool multiline;

  @override
  String get type => SemanticType.comment;

  TokenComment(this.literal, String moduleFullName, int line, int column,
      {this.multiline = false})
      : super(literal, moduleFullName, line, column);
}
