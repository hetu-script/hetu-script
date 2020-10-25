import 'environment.dart';

class Token {
  final String lexeme;

  final int line;
  final int column;

  dynamic get type => lexeme;
  dynamic get literal => lexeme;

  Token(this.lexeme, [this.line, this.column]) {}

  static Token get EOF => Token(env.lexicon.endOfFile);

  operator ==(dynamic tokenType) {
    return type == tokenType;
  }
}

class TokenIdentifier extends Token {
  @override
  dynamic get type => env.lexicon.identifier;

  TokenIdentifier(String lexeme, [int line, int column]) : super(lexeme, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  @override
  dynamic get type => env.lexicon.boolean;

  TokenBoolLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  @override
  dynamic get type => env.lexicon.number;

  TokenNumLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  dynamic get type => env.lexicon.string;

  TokenStringLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}
