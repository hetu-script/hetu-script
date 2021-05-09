/// Function types
enum FunctionType {
  normal,
  method,
  constructor,
  getter,
  setter,
  literal, // function expression with no function name
  nested, // function within function, may with name
}

enum FunctionAppendixType {
  none, // void
  type, // HTTypeid
  referConstructor, // constructor
}

enum TypeType {
  normal, // HTTypeid
  parameter,
  function, // HTFunctionTypeid
  struct,
  union,
}

/// Code module types
enum CodeType {
  /// A bare expression.
  expression,

  /// Module can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// Class can only have declarations (variables, functions).
  klass,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  function,

  /// A script can have all statements.
  script,
}

abstract class SemanticType {
  static const literalNullExpr = 'literal_null_expression';
  static const literalBooleanExpr = 'literal_boolean_expression';
  static const literalIntExpr = 'literal_integer_expression';
  static const literalFloatExpr = 'literal_float_expression';
  static const literalStringExpr = 'literal_string_expression';
  static const literalFunctionExpr = 'literal_function_expression';
  static const typeExpr = 'type_expression';
  static const groupExpr = 'group_expression';
  static const literalVectorExpr = 'vector_expression';
  static const typeExpression = 'type_expression';
  static const blockExpr = 'block_expression';
  static const symbolExpr = 'symbol_expression';
  static const unaryExpr = 'unary_expression';
  static const binaryExpr = 'binary_expression';
  static const ternaryExpr = 'ternary_expression';
  static const callExpr = 'call_expression';
  static const thisExpr = 'this_expression';
  static const assignExpr = 'assign_expression';
  static const subGetExpr = 'subscript_get_expression';
  static const subSetExpr = 'subscript_set_expression';
  static const memberGetExpr = 'member_get_expression';
  static const memberSetExpr = 'member_set_expression';

  static const importStmt = 'import_statement';
  static const varDeclStmt = 'variable_declaration_statement';
  static const paramStmt = 'parameter_declaration_statement';
  static const exprStmt = 'expression_statement';
  static const blockStmt = 'block_statement';
  static const returnStmt = 'return_statement';
  static const breakStmt = 'break_statement';
  static const continueStmt = 'continue_statement';
  static const ifStmt = 'if_statement';
  static const doStmt = 'do_statement';
  static const whileStmt = 'while_statement';
  static const forStmtInit = 'for_statement_init';
  static const forStmt = 'for_statement';
  static const whenStmt = 'when_statement';
  static const classDeclStmt = 'class_declaration_statement';
  static const enumDeclStmt = 'enum_declaration_statement';
  static const funcDeclStmt = 'function_declaration_statement';

  static const module = 'module';
  static const library = 'library';
}
