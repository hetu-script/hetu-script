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

class HT_Lexicon {
  const HT_Lexicon();

  final defaultProgramMainFunc = 'main';

  final scriptPattern = r'(//.*)|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
      r'(\.\.\.|\|\||&&|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
      r'("(\\"|[^"])*"))';

  final commandLinePattern = r'(//.*)|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
      r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!:\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
      r'("(\\"|[^"])*"))';

  final tokenGroupComment = 1;
  final tokenGroupIdentifier = 2;
  final tokenGroupPunctuation = 3;
  final tokenGroupNumber = 4;
  final tokenGroupString = 6;

  final number = 'num';
  final boolean = 'bool';
  final string = 'str';

  Set<String> get literals => {
        number,
        boolean,
        string,
      };

  final endOfFile = 'end_of_file'; // 文件末尾
  final newLine = '\n';
  final multiline = '\\';
  final variadicArguments = '...';
  final underscore = '_';
  final globals = '__globals__';
  final externs = '__externs__';
  final instance = '__instance_of_';
  final instancePrefix = 'instance of ';
  final constructor = '__construct__';
  final getter = '__get__';
  final setter = '__set__';

  final object = 'Object';
  final unknown = '__unknown__';
  final list = 'List';
  final map = 'Map';
  final length = 'length';
  final function = 'function';
  final procedure = 'procedure';
  final identifier = 'identifier';

  final TRUE = 'true';
  final FALSE = 'false';
  final NULL = 'null';

  final VOID = 'void';
  final VAR = 'var';
  final LET = 'let';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  final ANY = 'any';
  final TYPEDEF = 'typedef';

  final STATIC = 'static';
  final FINAL = 'final';
  final CONSTRUCT = 'construct';
  final GET = 'get';
  final SET = 'set';
  final NAMESPACE = 'namespace';
  final AS = 'as';
  final ABSTRACT = 'abstract';
  final CLASS = 'class';
  final STRUCT = 'struct';
  final INTERFACE = 'interface';
  final FUN = 'fun';
  final PROC = 'proc';
  final THIS = 'this';
  final SUPER = 'super';
  final EXTENDS = 'extends';
  final IMPLEMENTS = 'implements';
  final MIXIN = 'mixin';
  final EXTERNAL = 'external';
  final IMPORT = 'import';

  final ASSERT = 'assert';
  final BREAK = 'break';
  final CONTINUE = 'continue';
  final FOR = 'for';
  final IN = 'in';
  final IF = 'if';
  final ELSE = 'else';
  final RETURN = 'return';
  final WHILE = 'while';
  final DO = 'do';
  final WHEN = 'when';

  final IS = 'is';

  /// 保留字，不能用于变量名字
  Set<String> get keywords => {
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
  final nullExpr = 'null_expression';
  final literalExpr = 'literal_expression';
  final groupExpr = 'group_expression';
  final vectorExpr = 'vector_expression';
  final blockExpr = 'block_expression';
  final varExpr = 'variable_expression';
  final typeExpr = 'type_expression';
  final unaryExpr = 'unary_expression';
  final binaryExpr = 'binary_expression';
  final callExpr = 'call_expression';
  final thisExpr = 'this_expression';
  final assignExpr = 'assign_expression';
  final subGetExpr = 'subscript_get_expression';
  final subSetExpr = 'subscript_set_expression';
  final memberGetExpr = 'member_get_expression';
  final memberSetExpr = 'member_set_expression';

  final importStmt = 'import_statement';
  final varStmt = 'variable_statement';
  final exprStmt = 'expression_statement';
  final blockStmt = 'block_statement';
  final returnStmt = 'return_statement';
  final breakStmt = 'break_statement';
  final continueStmt = 'continue_statement';
  final ifStmt = 'if_statement';
  final whileStmt = 'while_statement';
  final forInStmt = 'for_in_statement';
  final classStmt = 'class_statement';
  final funcStmt = 'function_statement';
  final externFuncStmt = 'external_function_statement';
  final constructorStmt = 'constructor_function_statement';

  final memberGet = '.';
  final subGet = '[';
  final call = '(';

  /// 后缀操作符，包含多个符号
  Set<String> get unaryPostfixs => {
        memberGet,
        subGet,
        call,
      };

  final not = '!';
  final negative = '-';

  /// 前缀操作符，包含多个符号
  Set<String> get unaryPrefixs => {
        not,
        negative,
      };

  final multiply = '*';
  final devide = '/';
  final modulo = '%';

  /// 乘除操作符，包含多个符号
  Set<String> get multiplicatives => {
        multiply,
        devide,
        modulo,
      };

  final add = '+';
  final subtract = '-';

  /// 加减操作符，包含多个符号
  Set<String> get additives => {
        add,
        subtract,
      };

  final greater = '>';
  final greaterOrEqual = '>=';
  final lesser = '<';
  final lesserOrEqual = '<=';

  /// 大小判断操作符，包含多个符号
  Set<String> get relationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        IS,
      };

  final equal = '==';
  final notEqual = '!=';

  /// 相等判断操作符，包含多个符号
  Set<String> get equalitys => {
        equal,
        notEqual,
      };

  final and = '&&';
  final or = '||';

  final assign = '=';

  /// 赋值类型操作符，包含多个符号
  Set<String> get assignments => {
        assign,
      };

  final comma = ',';
  final colon = ':';
  final semicolon = ';';
  final roundLeft = '(';
  final roundRight = ')';
  final curlyLeft = '{';
  final curlyRight = '}';
  final squareLeft = '[';
  final squareRight = ']';
  final angleLeft = '<';
  final angleRight = '>';

  Set<String> get Punctuations => {
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

  final errorUnsupport = 'Unsupport value type';
  final errorExpected = 'expected, ';
  final errorUnexpected = 'Unexpected identifier';
  final errorPrivate = 'Could not acess private member';
  final errorInitialized = 'has not initialized';
  final errorUndefined = 'Undefined identifier';
  final errorUndefinedOperator = 'Undefined operator';
  final errorDeclared = 'is already declared';
  final errorDefined = 'is already defined';
  final errorRange = 'Index out of range, should be less than';
  final errorInvalidLeftValue = 'Invalid left-value';
  final errorCallable = 'is not callable';
  final errorUndefinedMember = 'isn\'t defined for the class';
  final errorCondition = 'Condition expression must evaluate to type "bool"';
  final errorMissingFuncDef = 'Missing function definition body of';
  final errorGet = 'is not a collection or object';
  final errorSubGet = 'is not a List or Map';
  final errorExtends = 'is not a class';
  final errorSetter = 'Setter function\'s arity must be 1';
  final errorNullObject = 'is null';
  final errorMutable = 'is immutable';
  final errorNotType = 'is not a type.';

  final errorOfType = 'of type';

  final errorType1 = 'Variable';
  final errorType2 = 'can\'t be assigned with type';

  final errorArgType1 = 'Argument';
  final errorArgType2 = 'doesn\'t match parameter type';

  final errorReturnType1 = 'Value of type';
  final errorReturnType2 = 'can\'t be returned from function';
  final errorReturnType3 = 'because it has a return type of';

  final errorArity1 = 'Number of arguments';
  final errorArity2 = 'doesn\'t match parameter requirement of function';
}

const defaultLexicon = HT_Lexicon();
