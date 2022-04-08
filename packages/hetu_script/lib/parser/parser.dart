import '../ast/ast.dart';
import '../source/source.dart';
import 'token.dart';

/// Determines how to parse a piece of code
enum ParseStyle {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body.
  script,

  /// An expression.
  expression,

  /// Like module, but no import & export allowed.
  namespace,

  /// Class can only have declarations (variables, functions).
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

abstract class ParserConfig {}

class ParserConfigImpl implements ParserConfig {}

/// Convert tokens into [ASTSource] by a certain grammar rules set.
abstract class HTParser {
  /// the identity name of this parser.
  String get name;

  /// Will use `style` when possible, then `source.sourceType`
  List<ASTNode> parseToken(Token token,
      {HTSource? source, ParseStyle? style, ParserConfig? config});

  ASTSource parseSource(HTSource source);
}
