/// All lexicons used by hetu
abstract class HTLexicon {
  static const defaultProgramMainFunc = 'main';

  static const scriptPattern = r'((/\*[\s\S]*?\*/)|(//.*))|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(4)
      r'(\.\.\.|\|\||&&|\+\+|--|\*=|/=|\+=|-=|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(5)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // 数字字面量 group(6)
      // r'(\d+\.\d+)|' // 浮点数字面量 group(6)
      // r'((?<![\d.])[0-9]+(?![\d.]))|' // 整数字面量 group(7)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(8)
      r'("(\\"|[^"])*"))';

  static const stringReplaces = <String, String>{
    '\\\\': '\\',
    '\\n': '\n',
    '\\\'': '\'',
  };

  static String convertStringLiteral(String literal) {
    var result = literal.substring(1).substring(0, literal.length - 2);
    for (final key in stringReplaces.keys) {
      result = result.replaceAll(key, stringReplaces[key]!);
    }
    return result;
  }

  /// Add semicolon before a line
  /// starting with one of '[, (, +, -, /'
  static const Set<String> ASIStart = {
    squareLeft,
    roundLeft,
    add,
    preIncrement,
    subtract,
    preDecrement,
    devide,
  };

  /// Add semicolon after a line
  /// ending with 'return'
  static const Set<String> ASIEnding = {
    BREAK,
    CONTINUE,
    RETURN,
  };

  static const tokenGroupComment = 1;
  static const tokenGroupIdentifier = 4;
  static const tokenGroupPunctuation = 5;
  static const tokenGroupNumber = 6;
  static const tokenGroupFloat = 6;
  static const tokenGroupInt = 7;
  static const tokenGroupString = 8;

  static const boolean = 'bool';
  static const number = 'num';
  static const integer = 'int';
  static const float = 'float';
  static const string = 'str';
  static const keys = 'keys';
  static const values = 'values';

  static const Set<String> literals = {
    number,
    boolean,
    string,
  };

  static const endOfFile = 'end_of_file'; // 文件末尾
  static const multiline = '\\';
  static const varargs = '...'; // variadic arguments
  static const anonymousScript = '__anonymousScript#';
  static const anonymousFunction = '__anonymousFunction#';
  static const anonymousNamespace = '__anonymousNamespace#';
  static const functionCall = 'call';
  static const underscore = '_';
  static const global = 'global';
  static const unknown = 'unknown';
  // static const extern = 'external__';
  // static const method = '__method__';
  static const instance = '__instance#';
  static const constructor = '__constructor__';
  static const getter = '__getter__';
  static const setter = '__setter__';

  static const instanceOf = 'instance of ';
  static const rootClass = 'Object';
  static const function = 'function';
  static const list = 'List';
  static const map = 'Map';
  static const length = 'length';
  // static const procedure = 'procedure';
  static const identifier = 'identifier';

  static const TRUE = 'true';
  static const FALSE = 'false';
  static const NULL = 'null';

  static const VAR = 'var';
  static const LET = 'let';
  static const FINAL = 'final';
  static const CONST = 'const';

  /// 变量声明
  static const Set<String> varDeclKeywords = {
    VAR,
    LET,
    FINAL,
    CONST,
  };

  static const VOID = 'void';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  static const ANY = 'any';
  static const TYPEDEF = 'typedef';

  static const CONSTRUCT = 'construct';
  static const GET = 'get';
  static const SET = 'set';

  static const STATIC = 'static';
  static const NAMESPACE = 'namespace';
  static const AS = 'as';
  static const SHOW = 'show';
  static const CLASS = 'class';
  static const ENUM = 'enum';
  static const STRUCT = 'struct';
  static const FUN = 'fun';
  static const ASYNC = 'async';
  static const THIS = 'this';
  static const SUPER = 'super';
  static const EXTENDS = 'extends';
  static const IMPLEMENTS = 'implements';
  static const EXTERNAL = 'external';
  static const IMPORT = 'import';

  static const ABSTRACT = 'abstract';
  static const INTERFACE = 'interface';
  static const MIXIN = 'mixin';

  /// 类名修饰符
  static const Set<String> classPrefixs = {
    EXTERNAL,
    ABSTRACT,
    INTERFACE,
    MIXIN,
  };

  static const AWAIT = 'await';
  static const ASSERT = 'assert';
  static const BREAK = 'break';
  static const CONTINUE = 'continue';
  static const FOR = 'for';
  static const IN = 'in';
  static const OF = 'of';
  static const IF = 'if';
  static const ELSE = 'else';
  static const RETURN = 'return';
  static const WHILE = 'while';
  static const DO = 'do';
  static const WHEN = 'when';

  static const IS = 'is';

  /// 保留字，不能用于变量名字
  static const Set<String> reservedKeywords = {
    NULL,
    STATIC,
    VAR,
    LET,
    FINAL,
    CONST,
    TYPEDEF,
    AS,
    CLASS,
    ENUM,
    STRUCT,
    INTERFACE,
    CONSTRUCT,
    GET,
    SET,
    FUN,
    ASYNC,
    AWAIT,
    VOID,
    //THIS,
    //SUPER,
    EXTENDS,
    IMPLEMENTS,
    MIXIN,
    EXTERNAL,
    IMPORT,
    BREAK,
    CONTINUE,
    FOR,
    IN,
    OF,
    IF,
    ELSE,
    RETURN,
    WHILE,
    DO,
    WHEN,
    IS,
  };

  /// 函数调用表达式
  static const nullExpr = 'null_expression';
  static const literalBooleanExpr = 'literal_boolean_expression';
  static const literalIntExpr = 'literal_integer_expression';
  static const literalFloatExpr = 'literal_float_expression';
  static const literalStringExpr = 'literal_string_expression';
  static const literalFunctionExpr = 'literal_function_expression';
  static const groupExpr = 'group_expression';
  static const literalVectorExpr = 'vector_expression';
  static const blockExpr = 'block_expression';
  static const symbolExpr = 'symbol_expression';
  static const typeExpr = 'type_expression';
  static const unaryExpr = 'unary_expression';
  static const binaryExpr = 'binary_expression';
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
  static const thenBranch = 'then_branch';
  static const elseBranch = 'else_branch';
  static const doStmt = 'do_statement';
  static const whileStmt = 'while_statement';
  static const forStmtInit = 'for_statement_init';
  static const forStmt = 'for_statement';
  static const whenStmt = 'when_statement';
  static const classDeclStmt = 'class_declaration_statement';
  static const enumDeclStmt = 'enum_declaration_statement';
  static const funcDeclStmt = 'function_declaration_statement';

  static const memberGet = '.';
  static const subGet = '[';
  static const call = '(';
  static const nullable = '?';
  static const postIncrement = '++';
  static const postDecrement = '--';

  /// 后缀操作符，包含多个符号
  static const Set<String> unaryPostfixs = {
    memberGet,
    subGet,
    call,
    postIncrement,
    postDecrement,
  };

  static const logicalNot = '!';
  static const negative = '-';
  static const preIncrement = '++';
  static const preDecrement = '--';

  /// 前缀操作符，包含多个符号
  static const Set<String> unaryPrefixs = {
    logicalNot,
    negative,
    preIncrement,
    preDecrement,
  };

  static const multiply = '*';
  static const devide = '/';
  static const modulo = '%';

  /// 乘除操作符，包含多个符号
  static const Set<String> multiplicatives = {
    multiply,
    devide,
    modulo,
  };

  static const add = '+';
  static const subtract = '-';

  /// 加减操作符，包含多个符号
  static const Set<String> additives = {
    add,
    subtract,
  };

  static const greater = '>';
  static const greaterOrEqual = '>=';
  static const lesser = '<';
  static const lesserOrEqual = '<=';

  /// 大小判断操作符，包含多个符号
  static const Set<String> relationals = {
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
    IS,
  };

  static const equal = '==';
  static const notEqual = '!=';

  /// 相等判断操作符，包含多个符号
  static const Set<String> equalitys = {
    equal,
    notEqual,
  };

  static const logicalAnd = '&&';
  static const logicalOr = '||';

  static const assign = '=';
  static const assignMultiply = '*=';
  static const assignDevide = '/=';
  static const assignAdd = '+=';
  static const assignSubtract = '-=';

  /// 赋值类型操作符，包含多个符号
  static const Set<String> assignments = {
    assign,
    assignMultiply,
    assignDevide,
    assignAdd,
    assignSubtract,
  };

  static const comma = ',';
  static const colon = ':';
  static const semicolon = ';';
  static const roundLeft = '(';
  static const roundRight = ')';
  static const curlyLeft = '{';
  static const curlyRight = '}';
  static const squareLeft = '[';
  static const squareRight = ']';
  static const angleLeft = '<';
  static const angleRight = '>';

  static const Set<String> Punctuations = {
    nullable,
    logicalNot,
    multiply,
    devide,
    modulo,
    add,
    subtract,
    lesser, // angleLeft,
    lesserOrEqual,
    greater, // angleRight,
    greaterOrEqual,
    equal,
    notEqual,
    logicalAnd,
    logicalOr,
    assign,
    comma,
    colon,
    semicolon,
    memberGet,
    roundLeft,
    roundRight,
    curlyLeft,
    curlyRight,
    squareLeft,
    squareRight,
  };

  static const math = 'Math';
  static const system = 'System';
  static const console = 'Console';
}
