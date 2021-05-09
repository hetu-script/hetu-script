import 'lexicon.dart';

class Token {
  final String lexeme;

  final String moduleFullName;
  final int line;
  final int column;

  dynamic get type => lexeme;
  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  Token(this.lexeme, this.moduleFullName, this.line, this.column);
}

class TokenIdentifier extends Token {
  @override
  dynamic get type => HTLexicon.identifier;

  TokenIdentifier(String lexeme, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  @override
  dynamic get type => lexeme;

  TokenBoolLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenNumberLiteral extends Token {
  @override
  final num literal;

  @override
  dynamic get type => HTLexicon.number;

  TokenNumberLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenIntLiteral extends Token {
  @override
  final int literal;

  @override
  dynamic get type => HTLexicon.integer;

  TokenIntLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenFloatLiteral extends Token {
  @override
  final double literal;

  @override
  dynamic get type => HTLexicon.float;

  TokenFloatLiteral(
      String lexeme, this.literal, String moduleFullName, int line, int column)
      : super(lexeme, moduleFullName, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  dynamic get type => HTLexicon.string;

  TokenStringLiteral(this.literal, String moduleFullName, int line, int column)
      : super(literal, moduleFullName, line, column);
}
