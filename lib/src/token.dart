import 'common.dart';

class Token {
  final String type;

  final int line;
  final int column;

  String get lexeme => type;
  dynamic get literal => type;

  const Token(this.type, this.line, this.column);

  static Token get EOF => Token(HS_Common.EOF, -1, -1);

  operator ==(dynamic tokenType) {
    return type == tokenType;
  }
}

class TokenIdentifier extends Token {
  @override
  final String lexeme;

  const TokenIdentifier(this.lexeme, int line, int column) : super(HS_Common.Identifier, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  String get lexeme => literal.toString();

  const TokenBoolLiteral(this.literal, int line, int column) : super(HS_Common.Boolean, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  String get lexeme => literal.toString();

  const TokenNumLiteral(this.literal, int line, int column) : super(HS_Common.Number, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  String get lexeme => literal;

  const TokenStringLiteral(this.literal, int line, int column) : super(HS_Common.Str, line, column);
}
