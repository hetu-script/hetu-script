import '../common/internal_identifier.dart';

class Token {
  /// `end_of_file` token lexeme.
  static const endOfFile = 'end_of_file';

  final String lexeme;

  final int line;

  final int column;

  /// the start position of this token
  final int offset;

  int get length => lexeme.length;

  int get end => offset + length;

  // String get type => lexeme;

  dynamic get literal => lexeme;

  final bool isKeyword;

  Token? previous;

  Token? next;

  @override
  String toString() => lexeme;

  Token({
    required this.lexeme,
    required this.line,
    required this.column,
    required this.offset,
    this.isKeyword = false,
    this.previous,
    this.next,
  });
}

class TokenComment extends Token {
  // @override
  // String get type => InternalIdentifier.comment;

  @override
  final String literal;

  final bool isDocumentation;

  final bool isMultiLine;

  final bool isTrailing;

  TokenComment({
    required super.lexeme,
    required super.line,
    required super.column,
    required super.offset,
    super.previous,
    super.next,
    required this.literal,
    this.isDocumentation = false,
    this.isMultiLine = false,
    this.isTrailing = false,
  });
}

class TokenEmptyLine extends Token {
  TokenEmptyLine(
      {required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next})
      : super(lexeme: InternalIdentifier.emptyLine);
}

class TokenIdentifier extends Token {
  // @override
  // String get type => InternalIdentifier.identifier;

  /// whether this identifier is marked by grave accent marks.
  final bool isMarked;

  @override
  final String literal;

  TokenIdentifier(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      this.isMarked = false})
      : literal = isMarked ? lexeme.substring(1, lexeme.length - 1) : lexeme;
}

class TokenBooleanLiteral extends Token {
  // @override
  // String get type => InternalIdentifier.literalBoolean;

  @override
  final bool literal;

  TokenBooleanLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenIntegerLiteral extends Token {
  // @override
  // String get type => InternalIdentifier.literalInteger;

  @override
  final int literal;

  TokenIntegerLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenFloatLiteral extends Token {
  // @override
  // String get type => InternalIdentifier.literalFloat;

  @override
  final double literal;

  TokenFloatLiteral(
      {required super.lexeme,
      required super.line,
      required super.column,
      required super.offset,
      super.previous,
      super.next,
      required this.literal});
}

class TokenStringLiteral extends Token {
  // @override
  // String get type => InternalIdentifier.literalString;

  final String _literal;

  @override
  String get literal => _literal;

  final String startMark, endMark;

  TokenStringLiteral({
    required super.lexeme,
    required super.line,
    required super.column,
    required super.offset,
    super.previous,
    super.next,
    required this.startMark,
    required this.endMark,
  }) : _literal = lexeme.substring(1, lexeme.length - 1);
}

class TokenStringInterpolation extends TokenStringLiteral {
  // @override
  // String get type => InternalIdentifier.stringInterpolation;

  final List<Token> interpolations;

  TokenStringInterpolation({
    required super.lexeme,
    required super.line,
    required super.column,
    required super.offset,
    super.previous,
    super.next,
    required super.startMark,
    required super.endMark,
    required this.interpolations,
  });
}
