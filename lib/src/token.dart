import 'lexicon.dart';

class Token {
  final String lexeme;

  final int? line;
  final int? column;

  dynamic get type => lexeme;
  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  Token(this.lexeme, [this.line, this.column]);

  static Token get EOF => Token(HT_Lexicon.endOfFile);
}

class TokenIdentifier extends Token {
  @override
  dynamic get type => HT_Lexicon.identifier;

  TokenIdentifier(String lexeme, [int? line, int? column]) : super(lexeme, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  @override
  dynamic get type => lexeme;

  TokenBoolLiteral(String lexeme, this.literal, [int? line, int? column]) : super(lexeme, line, column);
}

class TokenIntLiteral extends Token {
  @override
  final int literal;

  @override
  dynamic get type => HT_Lexicon.integer;

  TokenIntLiteral(String lexeme, this.literal, [int? line, int? column]) : super(lexeme, line, column);
}

class TokenFloatLiteral extends Token {
  @override
  final double literal;

  @override
  dynamic get type => HT_Lexicon.float;

  TokenFloatLiteral(String lexeme, this.literal, [int? line, int? column]) : super(lexeme, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  dynamic get type => HT_Lexicon.string;

  TokenStringLiteral(String lexeme, this.literal, [int? line, int? column]) : super(lexeme, line, column);
}
