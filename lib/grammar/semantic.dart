/// Function types
enum FunctionCategory {
  normal,
  method,
  constructor,
  factoryConstructor,
  getter,
  setter,
  literal, // function expression with no function name
  nested, // function within function, may with name
}

enum TypeType {
  normal, // HTTypeid
  function, // HTFunctionTypeid
  struct,
  interface,
  union,
}

abstract class SemanticType {
  static const emptyLine = 'empty_line';
  static const comment = 'comment';
  static const singleLineComment = 'single_line_comment';
  static const multiLineComment = 'multi_line_comment';

  static const identifier = 'identifier';
  static const punctuation = 'punctuation';
  static const expression = 'expression';
  static const statement = 'statement';
  static const declStmt = 'declaration_statement';
  static const thenBranch = 'then_branch';
  static const elseBranch = 'else_branch';
  static const whileLoop = 'while_loop';
  static const doLoop = 'do_loop';
  static const forLoop = 'for_loop';
  static const whenBranch = 'when_loop';
  static const functionCall = 'function_call';
  static const classDefinition = 'class_definition';
  static const ctorCallExpr = 'constructor_call_expression';

  static const literalNull = 'literal_null';
  static const literalValue = 'literal_value';
  static const literalBoolean = 'literal_boolean';
  static const literalInteger = 'literal_integer';
  static const literalFloat = 'literal_float';
  static const literalString = 'literal_string';
  static const literalFunction = 'literal_function_expression';

  static const typeExpr = 'type_expression';
  static const literalTypeExpr = 'literal_type_expression';
  static const unionTypeExpr = 'union_type_expression';
  static const paramTypeExpr = 'parameter_type_expression';
  static const funcTypeExpr = 'function_type_expression';
  static const groupExpr = 'group_expression';
  static const literalVectorExpr = 'vector_expression';
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

  static const variableDeclaration = 'variable_declaration';
  static const parameterDeclaration = 'parameter_declaration';
  static const classDeclaration = 'class_declaration';
  static const enumDeclaration = 'enum_declaration';
  static const typeAliasDeclaration = 'type_alias_declaration';
  static const referConstructorExpression = 'refer_constructor_expression';
  static const functionDeclaration = 'function_declaration';

  static const libraryStmt = 'library_statement';
  static const importStmt = 'import_statement';
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
  static const forInStmt = 'for_in_statement';
  static const whenStmt = 'when_statement';
}
