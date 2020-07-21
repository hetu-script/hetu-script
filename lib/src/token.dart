import 'common.dart';

class Token {
  final String type;

  final int line;
  final int column;

  dynamic get lexeme => type;
  dynamic get literal => type;

  const Token(this.type, this.line, this.column);

  static Token get EOF => Token(HS_Common.EOF, -1, -1);
}

class TokenIdentifier extends Token {
  @override
  final String lexeme;

  const TokenIdentifier(this.lexeme, int line, int column) : super(HS_Common.Identifier, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  const TokenBoolLiteral(this.literal, int line, int column) : super(HS_Common.Bool, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  const TokenNumLiteral(this.literal, int line, int column) : super(HS_Common.Num, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  const TokenStringLiteral(this.literal, int line, int column) : super(HS_Common.Str, line, column);
}
