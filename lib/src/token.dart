import 'constants.dart';

class Token {
  final String type;

  final int lineNumber;
  final int colNumber;

  dynamic get text => type;
  dynamic get literal => type;

  const Token(this.type, this.lineNumber, this.colNumber);

  static Token get EOF => Token(Constants.EOF, -1, -1);
}

class TokenIdentifier extends Token {
  @override
  final String text;

  const TokenIdentifier(this.text, int lineNumber, int colNumber) : super(Constants.Identifier, lineNumber, colNumber);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  const TokenBoolLiteral(this.literal, int lineNumber, int colNumber) : super(Constants.Bool, lineNumber, colNumber);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  const TokenNumLiteral(this.literal, int lineNumber, int colNumber) : super(Constants.Num, lineNumber, colNumber);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  const TokenStringLiteral(this.literal, int lineNumber, int colNumber) : super(Constants.Str, lineNumber, colNumber);
}
