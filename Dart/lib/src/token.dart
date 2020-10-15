import 'common.dart';

class Token {
  final String lexeme;
  final String type;

  final int line;
  final int column;

  dynamic get literal => type;

  Token(this.lexeme, this.type, this.line, this.column);

  static Token get EOF => Token(env.lexicon.endOfFile, env.lexicon.endOfFile, -1, -1);

  operator ==(dynamic tokenType) {
    return type == tokenType;
  }
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  TokenBoolLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, env.lexicon.boolean, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  String get lexeme => literal.toString();

  TokenNumLiteral(String lexeme, this.literal, int line, int column) : super(lexeme, env.lexicon.number, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  String get lexeme => literal;

  TokenStringLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, env.lexicon.string, line, column);
}
