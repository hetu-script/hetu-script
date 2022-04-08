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
  structural,
  union,
}

abstract class InternalIdentifier {
  static const prototype = r'$prototype';
  static const call = r'$call';
  static const instance = r'$instance';
  static const defaultConstructor = r'$construct';
  static const namedConstructorPrefix = r'$construct_';
  static const getter = r'$getter_';
  static const setter = r'$setter_';
  static const subGetter = r'$subscript_getter_';
  static const subSetter = r'$subscript_setter_';

  static const anonymousScript = r'$anonymous_script';
  static const anonymousClass = r'$anonymous_class';
  static const anonymousStruct = r'$anonymous_struct';
  static const anonymousFunction = r'$anonymous_function';
  static const anonymousBlock = r'$anonymous_block';

  static const instanceOfDescription = 'instance of';
  static const externalType = 'external type';
  static const nullValue = 'null';
}

abstract class Semantic {
  static const compilation = 'compilation';
  static const source = 'source';
  static const namespace = 'namespace';

  static const global = 'global';
  static const preclude = 'preclude';
  static const anonymous = 'anonymous';

  static const endOfFile = 'end_of_file';
  static const name = 'name';
  static const empty = 'empty';
  static const emptyLine = 'empty_line';
  static const comment = 'comment';

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
  static const asyncFunction = 'async_function';
  static const ctorFunction = 'constructor';
  static const factory = 'factory';
  static const classDefinition = 'class_definition';
  static const structDefinition = 'struct_definition';
  static const ctorCallExpr = 'constructor_call_expression';

  static const literalNull = 'literal_null';
  static const literalBoolean = 'literal_boolean';
  static const literalInteger = 'literal_integer';
  static const literalFloat = 'literal_float';
  static const literalString = 'literal_string';
  static const literalStringInterpolation = 'literal_string_interpolation';
  static const literalList = 'literal_list';
  static const literalFunction = 'literal_function';
  static const literalStruct = 'literal_struct';
  static const literalStructField = 'literal_struct_field';

  static const spreadExpr = 'spread_expression';
  static const rangeExpr = 'range_expression';
  static const groupExpr = 'group_expression';
  static const commaExpr = 'comma_expression';
  static const inExpr = 'in_expression';

  static const typeExpr = 'type_expression';
  static const literalTypeExpr = 'literal_type_expression';
  static const unionTypeExpr = 'union_type_expression';
  static const paramTypeExpr = 'parameter_type_expression';
  static const funcTypeExpr = 'function_type_expression';
  static const fieldTypeExpr = 'field_type_expression';
  static const structuralTypeExpr = 'structural_type_expression';
  static const genericTypeParamExpr = 'generic_type_parameter_expression';
  static const blockExpr = 'block_expression';
  static const identifierExpr = 'identifier_expression';
  static const unaryExpr = 'unary_expression';
  static const assignExpr = 'assign_expression';
  static const binaryExpr = 'binary_expression';
  static const ternaryExpr = 'ternary_expression';
  static const callExpr = 'call_expression';
  static const thisExpr = 'this_expression';
  static const subGetExpr = 'subscript_get_expression';
  static const subSetExpr = 'subscript_set_expression';
  static const memberGetExpr = 'member_get_expression';
  static const memberSetExpr = 'member_set_expression';

  static const constantDeclaration = 'constant_declaration';
  static const variableDeclaration = 'variable_declaration';
  static const destructuringDeclaration = 'destructuring_declaration';
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
  static const exportStmt = 'export_statement';
  static const exportImportStmt = 'export_import_statement';
  static const exprStmt = 'expression_statement';
  static const blockStmt = 'block_statement';
  static const assertStmt = 'assert_statement';
  static const throwStmt = 'throw_statement';
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
  static const deleteStmt = 'delete_statement';
  static const deleteMemberStmt = 'delete_member_statement';
  static const deleteSubMemberStmt = 'delete_subscript_member_statement';
}