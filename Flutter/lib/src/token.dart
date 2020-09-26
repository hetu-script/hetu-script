import 'common.dart';

class Token {
  final String lexeme;
  final String type;

  final int line;
  final int column;

  dynamic get literal => type;

  const Token(this.lexeme, this.type, this.line, this.column);

  static Token get EOF => Token(HS_Common.endOfFile, HS_Common.endOfFile, -1, -1);

  operator ==(dynamic tokenType) {
    return type == tokenType;
  }
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  const TokenBoolLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, HS_Common.boolean, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  String get lexeme => literal.toString();

  const TokenNumLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, HS_Common.number, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  String get lexeme => literal;

  const TokenStringLiteral(String lexeme, this.literal, int line, int column)
      : super(lexeme, HS_Common.string, line, column);
}
