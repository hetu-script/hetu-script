/// Hetu运算符优先级
/// Description     Operator           Associativity   Precedence
//  Unary postfix   e., e()            None            16
//  Unary prefix    -e, !e             None            15
//  Multiplicative  *, /, %            Left            14
//  Additive        +, -               Left            13
//  Relational      <, >, <=, >=, is   None            8
//  Equality        ==, !=             None            7
//  Logical AND     &&                 Left            6
//  Logical Or      ||                 Left            5
//  Assignment      =                  Right           1

/// Dart运算符优先级（参考用）
/// Description      Operator                             Associativity   Precedence
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

abstract class HT_Lexicon {
  static final defaultProgramMainFunc = 'main';

  static final scriptPattern = r'(//.*)|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
      r'(\.\.\.|\|\||&&|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
      r'("(\\"|[^"])*"))';

  static final commandLinePattern = r'(//.*)|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
      r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!:\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
      r'("(\\"|[^"])*"))';

  static final tokenGroupComment = 1;
  static final tokenGroupIdentifier = 2;
  static final tokenGroupPunctuation = 3;
  static final tokenGroupNumber = 4;
  static final tokenGroupString = 6;

  static final number = 'num';
  static final boolean = 'bool';
  static final string = 'str';

  static Set<String> get literals => {
        number,
        boolean,
        string,
      };

  static final endOfFile = 'end_of_file'; // 文件末尾
  static final newLine = '\n';
  static final multiline = '\\';
  static final variadicArguments = '...';
  static final underscore = '_';
  static final globals = '__globals__';
  static final externs = '__externs__';
  static final instance = '__instance_of_';
  static final instancePrefix = 'instance of ';
  static final constructor = '__construct__';
  static final getter = '__get__';
  static final setter = '__set__';

  static final object = 'Object';
  static final unknown = '__unknown__';
  static final list = 'List';
  static final map = 'Map';
  static final length = 'length';
  static final function = 'function';
  static final procedure = 'procedure';
  static final identifier = 'identifier';

  static final TRUE = 'true';
  static final FALSE = 'false';
  static final NULL = 'null';

  static final VOID = 'void';
  static final VAR = 'var';
  static final LET = 'let';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  static final ANY = 'any';
  static final TYPEDEF = 'typedef';

  static final STATIC = 'static';
  static final FINAL = 'final';
  static final CONSTRUCT = 'construct';
  static final GET = 'get';
  static final SET = 'set';
  static final NAMESPACE = 'namespace';
  static final AS = 'as';
  static final ABSTRACT = 'abstract';
  static final CLASS = 'class';
  static final STRUCT = 'struct';
  static final INTERFACE = 'interface';
  static final FUN = 'fun';
  static final PROC = 'proc';
  static final THIS = 'this';
  static final SUPER = 'super';
  static final EXTENDS = 'extends';
  static final IMPLEMENTS = 'implements';
  static final MIXIN = 'mixin';
  static final EXTERNAL = 'external';
  static final IMPORT = 'import';

  static final ASSERT = 'assert';
  static final BREAK = 'break';
  static final CONTINUE = 'continue';
  static final FOR = 'for';
  static final IN = 'in';
  static final IF = 'if';
  static final ELSE = 'else';
  static final RETURN = 'return';
  static final WHILE = 'while';
  static final DO = 'do';
  static final WHEN = 'when';

  static final IS = 'is';

  /// 保留字，不能用于变量名字
  static Set<String> get keywords => {
        NULL,
        STATIC,
        VAR,
        LET,
        ANY,
        TYPEDEF,
        NAMESPACE,
        AS,
        CLASS,
        STRUCT,
        INTERFACE,
        FUN,
        PROC,
        VOID,
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
        BREAK,
        CONTINUE,
        FOR,
        IN,
        IF,
        ELSE,
        RETURN,
        WHILE,
        DO,
        WHEN,
        IS,
      };

  /// 函数调用表达式
  static final nullExpr = 'null_expression';
  static final literalExpr = 'literal_expression';
  static final groupExpr = 'group_expression';
  static final vectorExpr = 'vector_expression';
  static final blockExpr = 'block_expression';
  static final varExpr = 'variable_expression';
  static final typeExpr = 'type_expression';
  static final unaryExpr = 'unary_expression';
  static final binaryExpr = 'binary_expression';
  static final callExpr = 'call_expression';
  static final thisExpr = 'this_expression';
  static final assignExpr = 'assign_expression';
  static final subGetExpr = 'subscript_get_expression';
  static final subSetExpr = 'subscript_set_expression';
  static final memberGetExpr = 'member_get_expression';
  static final memberSetExpr = 'member_set_expression';

  static final importStmt = 'import_statement';
  static final varStmt = 'variable_statement';
  static final exprStmt = 'expression_statement';
  static final blockStmt = 'block_statement';
  static final returnStmt = 'return_statement';
  static final breakStmt = 'break_statement';
  static final continueStmt = 'continue_statement';
  static final ifStmt = 'if_statement';
  static final whileStmt = 'while_statement';
  static final forInStmt = 'for_in_statement';
  static final classStmt = 'class_statement';
  static final funcStmt = 'function_statement';
  static final externFuncStmt = 'external_function_statement';
  static final constructorStmt = 'constructor_function_statement';

  static final memberGet = '.';
  static final subGet = '[';
  static final call = '(';

  /// 后缀操作符，包含多个符号
  static Set<String> get unaryPostfixs => {
        memberGet,
        subGet,
        call,
      };

  static final not = '!';
  static final negative = '-';

  /// 前缀操作符，包含多个符号
  static Set<String> get unaryPrefixs => {
        not,
        negative,
      };

  static final multiply = '*';
  static final devide = '/';
  static final modulo = '%';

  /// 乘除操作符，包含多个符号
  static Set<String> get multiplicatives => {
        multiply,
        devide,
        modulo,
      };

  static final add = '+';
  static final subtract = '-';

  /// 加减操作符，包含多个符号
  static Set<String> get additives => {
        add,
        subtract,
      };

  static final greater = '>';
  static final greaterOrEqual = '>=';
  static final lesser = '<';
  static final lesserOrEqual = '<=';

  /// 大小判断操作符，包含多个符号
  static Set<String> get relationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        IS,
      };

  static final equal = '==';
  static final notEqual = '!=';

  /// 相等判断操作符，包含多个符号
  static Set<String> get equalitys => {
        equal,
        notEqual,
      };

  static final and = '&&';
  static final or = '||';

  static final assign = '=';

  /// 赋值类型操作符，包含多个符号
  static Set<String> get assignments => {
        assign,
      };

  static final comma = ',';
  static final colon = ':';
  static final semicolon = ';';
  static final roundLeft = '(';
  static final roundRight = ')';
  static final curlyLeft = '{';
  static final curlyRight = '}';
  static final squareLeft = '[';
  static final squareRight = ']';
  static final angleLeft = '<';
  static final angleRight = '>';

  static Set<String> get Punctuations => {
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
        memberGet,
        roundLeft,
        roundRight,
        curlyLeft,
        curlyRight,
        squareLeft,
        squareRight,
        angleLeft,
        angleRight,
      };

  static final errorUnsupport = 'Unsupport value type';
  static final errorExpected = 'expected, ';
  static final errorUnexpected = 'Unexpected identifier';
  static final errorPrivate = 'Could not acess private member';
  static final errorInitialized = 'has not initialized';
  static final errorUndefined = 'Undefined identifier';
  static final errorUndefinedOperator = 'Undefined operator';
  static final errorDeclared = 'is already declared';
  static final errorDefined = 'is already defined';
  static final errorRange = 'Index out of range, should be less than';
  static final errorInvalidLeftValue = 'Invalid left-value';
  static final errorCallable = 'is not callable';
  static final errorUndefinedMember = 'isn\'t defined for the class';
  static final errorCondition = 'Condition expression must evaluate to type "bool"';
  static final errorMissingFuncDef = 'Missing function definition body of';
  static final errorGet = 'is not a collection or object';
  static final errorSubGet = 'is not a List or Map';
  static final errorExtends = 'is not a class';
  static final errorSetter = 'Setter function\'s arity must be 1';
  static final errorNullObject = 'is null';
  static final errorMutable = 'is immutable';
  static final errorNotType = 'is not a type.';

  static final errorOfType = 'of type';

  static final errorType1 = 'Variable';
  static final errorType2 = 'can\'t be assigned with type';

  static final errorArgType1 = 'Argument';
  static final errorArgType2 = 'doesn\'t match parameter type';

  static final errorReturnType1 = 'Value of type';
  static final errorReturnType2 = 'can\'t be returned from function';
  static final errorReturnType3 = 'because it has a return type of';

  static final errorArity1 = 'Number of arguments';
  static final errorArity2 = 'doesn\'t match parameter requirement of function';
}
