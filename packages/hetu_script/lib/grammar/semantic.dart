/// Function types
enum FunctionCategory {
  normal,
  method,
  constructor,
  factoryConstructor,
  getter,
  setter,
  literal, // function expression with no function name
}

enum TypeType {
  normal, // HTTypeid
  function, // HTFunctionTypeid
  struct,
  interface,
  union,
}

abstract class SemanticNames {
  static const module = 'module';
  static const library = 'library';
  static const namespace = 'namespace';

  static const global = 'global';
  static const extern = 'external';
  static const preclude = 'preclude';
  static const anonymous = 'anonymous';
  static const multiLine = r'\';
  static const newLine = '\n';

  static const internalMarker = r'$';
  static const analysisResult = r'analysis_result';
  static const anonymousLibrary = r'anonymous_library';
  static const anonymousScript = r'anonymous_script';
  static const anonymousClass = r'$anonymous_class';
  static const anonymousNamespace = r'$anonymous_namespace';
  static const anonymousFunction = r'$anonymous_function';
  static const anonymousBlock = r'$anonymous_block';
  static const anonymousStruct = r'$anonymous_struct';
  static const name = r'name';
  static const increment = r'$increment';
  static const iterable = r'$iterable';
  static const instance = r'$instance';
  static const constructor = r'$constructor_';
  static const getter = r'$get_';
  static const setter = r'$set_';
  static const prototype = r'$prototype';

  static const endOfFile = 'end_of_file';
  static const empty = 'empty';
  static const emptyLine = 'empty_line';
  static const comment = 'comment';
  static const singleLineComment = 'single_line_comment';
  static const multiLineComment = 'multi_line_comment';

  static const keyword = 'keyword';
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
  static const function = 'function';
  static const functionCall = 'function_call';
  static const functionDefinition = 'function_definition';
  static const classDefinition = 'class_definition';
  static const structDefinition = 'struct_definition';
  static const ctorCallExpr = 'constructor_call_expression';

  static const nullLiteral = 'null_literal';
  static const booleanLiteral = 'boolean_literal';
  static const integerLiteral = 'integer_literal';
  static const floatLiteral = 'float_literal';
  static const stringLiteral = 'string_literal';
  static const stringInterpolation = 'string_interpolation';
  static const functionLiteral = 'function_literal_expression';
  static const listLiteral = 'list_expression';
  static const mapLiteral = 'map_expression';

  static const typeExpr = 'type_expression';
  static const genericTypeParamExpr = 'generic_type_parameter_expression';
  static const literalTypeExpr = 'literal_type_expression';
  static const unionTypeExpr = 'union_type_expression';
  static const paramTypeExpr = 'parameter_type_expression';
  static const funcTypeExpr = 'function_type_expression';
  static const groupExpr = 'group_expression';
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
  static const namespaceDeclaration = 'namespace_declaration';
  static const classDeclaration = 'class_declaration';
  static const enumDeclaration = 'enum_declaration';
  static const typeAliasDeclaration = 'type_alias_declaration';
  static const returnType = 'return_type';
  static const redirectingFunctionDefinition =
      'redirecting_function_definition';
  static const redirectingConstructorCallExpression =
      'redirecting_constructor_call_expression';
  static const functionDeclaration = 'function_declaration';
  static const structDeclaration = 'struct_declaration';

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
