abstract class HS_LexPatterns {
  static final script = RegExp(
    r'(//.*)|' // 注释 group(1)
    r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
    r'(\.\.\.|\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
    r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
    r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
    r'("(\\"|[^"])*"))',
    unicode: true,
    multiLine: true,
  );
  static final commandLine = RegExp(
    r'(//.*)|' // 注释 group(1)
    r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
    r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!:\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
    r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
    r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
    r'("(\\"|[^"])*"))',
    unicode: true,
    multiLine: true,
  );
}

abstract class HS_Common {
  static var coreLibPath = 'hetu_core';
  static var mainFunc = 'main';

  static var currentLanguage = enUS;

  static const zhHans = 'zh-Hans';
  static const enUS = 'en-US';

  static const regCommentGrp = 1;
  static const regIdGrp = 2;
  static const regPuncGrp = 3;
  static const regNumGrp = 4;
  static const regStrGrp = 6;

  static const _stringReplaces = <String, String>{
    '\\\\': '\\',
    '\\n': '\n',
    '\\\'': '\'',
  };

  static String convertEscapeCode(String line) {
    for (var key in _stringReplaces.keys) {
      line = line.replaceAll(key, _stringReplaces[key]);
    }
    return line;
  }

  static const literals = <String>[
    boolean,
    number,
    string,
    NULL,
    //Array,
    //Dict,
  ];

  /// 保留字，不能用于变量名字
  static const keywords = <String>[
    //Newline,
    //Multiline,
    NULL,
    STATIC,
    //CONST,
    //Final,
    VAR,
    LET,
    ANY,
    TYPEDEF,
    NAMESPACE,
    AS,
    ABSTRACT,
    CLASS,
    FUN,
    //Arguments,
    CONSTRUCT,
    GET,
    SET,
    THIS,
    SUPER,
    EXTENDS,
    IMPLEMENTS,
    MIXIN,
    EXTERNAL,
    IMPORT,
    //Assert,
    BREAK,
    CONTINUE,
    FOR,
    IN,
    IF,
    ELSE,
    RETURN,
    THROW,
    WHILE,
    DO,
    WHEN,
    //TRY,
    //CATCH,
    //FINALLY,
    IS,
  ];

  static const Punctuations = <String>[
    not,
    multiply,
    devide,
    modulo,
    add,
    subtract,
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
    equal,
    notEqual,
    and,
    or,
    assign,
    comma,
    colon,
    semicolon,
    dot,
    roundLeft,
    roundRight,
    curlyLeft,
    curlyRight,
    squareLeft,
    squareRight,
    angleLeft,
    angleRight,
  ];

  static const endOfFile = 'end_of_file'; // 文件末尾
  static const newline = '\n';
  static const multiline = '\\';
  static const variadicArguments = '...';
  static const underscore = '_';
  static const global = '__global__';
  static const extern = '__extern__';
  static const instance = '__instance_of_';
  static const instanceName = 'instance of class ';
  static const constructFun = '_construct_';
  static const getFun = '_get_';
  static const setFun = '_set_';

  static const object = 'Object';
  static const number = 'Number';
  static const boolean = 'Boolean';
  static const string = 'String';
  static const list = 'List';
  static const map = 'Map';
  static const length = 'length';
  static const function = 'function';
  static const method = 'method';
  static const identifier = 'identifier';

  static const TRUE = 'true';
  static const FALSE = 'false';
  static const NULL = 'null';

  static const VOID = 'void';
  static const VAR = 'var';
  static const LET = 'let';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  static const ANY = 'any';
  static const TYPEDEF = 'typedef';

  static const STATIC = 'static';
  static const CONST = 'const';
  static const CONSTRUCT = 'construct';
  static const GET = 'get';
  static const SET = 'set';
  //static const Final = 'final';
  static const NAMESPACE = 'namespace';
  static const AS = 'as';
  static const ABSTRACT = 'abstract';
  static const CLASS = 'class';
  static const STRUCT = 'struct';
  static const UNION = 'union';
  static const FUN = 'fun';
  static const Arguments = 'arguments';
  static const THIS = 'this';
  static const SUPER = 'super';
  static const EXTENDS = 'extends';
  static const IMPLEMENTS = 'implements';
  static const MIXIN = 'mixin';
  static const EXTERNAL = 'external';
  static const IMPORT = 'import';

  static const Assert = 'assert';
  static const BREAK = 'break';
  static const CONTINUE = 'continue';
  static const FOR = 'for';
  static const IN = 'in';
  static const IF = 'if';
  static const ELSE = 'else';
  static const RETURN = 'return';
  static const THROW = 'throw';
  static const WHILE = 'while';
  static const DO = 'do';
  static const WHEN = 'when';
  static const TRY = 'try';
  static const CATCH = 'catch';
  static const FINALLY = 'finally';

  /// 函数调用表达式
  static const nullExpr = 'null_expression';
  static const literalExpr = 'literal_expression';
  static const groupExpr = 'group_expression';
  static const vectorExpr = 'vector_expression';
  static const BlockExpr = 'block_expression';
  static const VarExpr = 'variable_expression';
  static const TypeExpr = 'type_expression';
  static const UnaryExpr = 'unary_expression';
  static const BinaryExpr = 'binary_expression';
  static const CallExpr = 'call_expression';
  static const ThisExpr = 'this_expression';
  static const AssignExpr = 'assign_expression';
  static const SubGetExpr = 'subscript_get_expression';
  static const SubSetExpr = 'subscript_set_expression';
  static const MemberGetExpr = 'member_get_expression';
  static const MemberSetExpr = 'member_set_expression';

  static const ImportStmt = 'import_statement';
  static const VarStmt = 'variable_statement';
  static const ExprStmt = 'expression_statement';
  static const BlockStmt = 'block_statement';
  static const ReturnStmt = 'return_statement';
  static const BreakStmt = 'break_statement';
  static const ContinueStmt = 'continue_statement';
  static const IfStmt = 'if_statement';
  static const WhileStmt = 'while_statement';
  static const ForInStmt = 'for_in_statement';
  static const ClassStmt = 'class_statement';
  static const FuncStmt = 'function_statement';
  static const ExternFuncStmt = 'external_function_statement';
  static const ConstructorStmt = 'constructor_function_statement';

  /// 后缀操作符，包含多个符号
  static const unaryPostfixs = <String>[
    dot,
    roundLeft,
    squareLeft,
  ];

  /// 前缀操作符，包含多个符号
  static const unaryPrefixs = <String>[
    not,
    subtract,
  ];
  static const not = '!';

  /// 乘除操作符，包含多个符号
  static const multiplicatives = <String>[
    multiply,
    devide,
    modulo,
  ];
  static const multiply = '*';
  static const devide = '/';
  static const modulo = '%';

  /// 加减操作符，包含多个符号
  static const additives = <String>[
    add,
    subtract,
  ];
  static const add = '+';
  static const subtract = '-';

  /// 大小判断操作符，包含多个符号
  static const relationals = <String>[
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
    IS,
  ];
  static const greater = '>';
  static const greaterOrEqual = '>=';
  static const lesser = '<';
  static const lesserOrEqual = '<=';
  static const IS = 'is';

  /// 相等判断操作符，包含多个符号
  static const equalitys = <String>[
    equal,
    notEqual,
  ];
  static const equal = '==';
  static const notEqual = '!=';

  static const and = '&&';
  static const or = '||';

  /// 赋值类型操作符，包含多个符号
  static const assignments = <String>[
    assign,
  ];
  static const assign = '=';
  static const comma = ',';
  static const colon = ':';
  static const semicolon = ';';
  static const dot = '.';
  static const roundLeft = '(';
  static const roundRight = ')';
  static const curlyLeft = '{';
  static const curlyRight = '}';
  static const squareLeft = '[';
  static const squareRight = ']';
  static const angleLeft = '<';
  static const angleRight = '>';

  static const errorUnsupport = 'Unsupport value type';
  static const errorExpected = 'expected, get';
  static const errorUnexpected = 'Unexpected identifier';
  static const errorPrivate = 'Could not acess private member';
  static const errorInitialized = 'has not initialized';
  static const errorUndefined = 'Undefined identifier';
  static const errorUndefinedOperator = 'Undefined operator';
  static const errorDeclared = 'is already declared';
  static const errorDefined = 'is already defined';
  static const errorRange = 'Index out of range, should be less than';
  static const errorInvalidLeftValue = 'Invalid left-value';
  static const ErrorCallable = 'is not callable';
  static const ErrorUndefinedMember = 'isn\'t defined for the class';
  static const ErrorCondition = 'Condition expression must evaluate to type "bool"';
  static const ErrorMissingFuncDef = 'Missing function definition body of';
  static const ErrorGet = 'is not a collection or object';
  static const ErrorSubGet = 'is not a List or Map';
  static const ErrorExtends = 'is not a class';
  static const ErrorSetter = 'Setter function\'s arity must be 1';
  static const ErrorNullObject = 'is null';
  static const ErrorMutable = 'is immutable';

  static const ErrorType1 = 'Variable';
  static const ErrorType2 = 'of type';
  static const ErrorType3 = 'can\'t be assigned with type';

  static const ErrorTypeParam1 = 'Type parameter declared as';
  static const ErrorTypeParam2 = 'can\'t be assigned with type argument';

  static const ErrorArgType1 = 'Argument value type';
  static const ErrorArgType2 = 'doesn\'t match parameter type';

  static const ErrorReturnType1 = 'Value of type';
  static const ErrorReturnType2 = 'can\'t be returned from function';
  static const ErrorReturnType3 = 'because it has a return type of';

  static const ErrorArity1 = 'Number of arguments';
  static const ErrorArity2 = 'doesn\'t match parameter requirement of function';
}

// Hetu运算符优先级
// Description     Operator           Associativity   Precedence
//  Unary postfix   e., e()            None            16
//  Unary prefix    -e, !e             None            15
//  Multiplicative  *, /, %            Left            14
//  Additive        +, -               Left            13
//  Relational      <, >, <=, >=, is   None            8
//  Equality        ==, !=             None            7
//  Logical AND     &&                 Left            6
//  Logical Or      ||                 Left            5
//  Assignment      =                  Right           1

// Dart运算符优先级（参考用）
// Description      Operator                             Associativity   Precedence
//  Unary postfix    e., e?., e++, e--, e1[e2], e()       None            16
//  Unary prefix     -e, !e, ˜e, ++e, --e, await e        None            15
//  Multiplicative   *, /, ˜/, %                          Left            14
//  Additive         +, -                                 Left            13
//  Shift            <<, >>, >>>                          Left            12
//  Bitwise          AND &                                Left            11
//  Bitwise          XOR ˆ                                Left            10
//  Bitwise          Or |                                 Left            9
//  Relational       <, >, <=, >=, as, is, is!            None            8
//  Equality         ==, !=                               None            7
//  Logical AND      &&                                   Left            6
//  Logical Or       ||                                   Left            5
//  If-null          ??                                   Left            4
//  Conditional      e1 ? e2 : e3                         Right           3
//  Cascade          ..                                   Left            2
//  Assignment       =, *=, /=, +=, -=, &=, ˆ=, etc.      Right           1
