import 'environment.dart';

class Token {
  final String lexeme;

  final int line;
  final int column;

  dynamic get type => lexeme;
  dynamic get literal => lexeme;

  @override
  String toString() => lexeme;

  Token(this.lexeme, [this.line, this.column]) {}

  static Token get EOF => Token(hetuEnv.lexicon.endOfFile);

  operator ==(dynamic tokenType) {
    return type == tokenType;
  }
}

class TokenIdentifier extends Token {
  @override
  dynamic get type => hetuEnv.lexicon.identifier;

  TokenIdentifier(String lexeme, [int line, int column]) : super(lexeme, line, column);
}

class TokenBoolLiteral extends Token {
  @override
  final bool literal;

  @override
  dynamic get type => hetuEnv.lexicon.boolean;

  TokenBoolLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}

class TokenNumLiteral extends Token {
  @override
  final num literal;

  @override
  dynamic get type => hetuEnv.lexicon.number;

  TokenNumLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}

class TokenStringLiteral extends Token {
  @override
  final String literal;

  @override
  dynamic get type => hetuEnv.lexicon.string;

  TokenStringLiteral(String lexeme, this.literal, [int line, int column]) : super(lexeme, line, column);
}
