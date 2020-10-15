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

class HS_Lexicons {
  const HS_Lexicons();

  String get defaultProgramMainFunc => 'main';

  RegExp get regexp => RegExp(
        r'(//.*)|' // 注释 group(1)
        r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
        r'(\.\.\.|\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
        r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
        r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
        r'("(\\"|[^"])*"))',
        unicode: true,
        multiLine: true,
      );

  int get tokenGroupComment => 1;
  int get tokenGroupIdentifier => 2;
  int get tokenGroupPunctuation => 3;
  int get tokenGroupNumber => 4;
  int get tokenGroupString => 6;

  String get number => 'num';
  String get boolean => 'bool';
  String get string => 'str';

  Set<String> get literals => {
        number,
        boolean,
        string,
      };

  String get endOfFile => 'end_of_file'; // 文件末尾
  String get newLine => '\n';
  String get multiline => '\\';
  String get variadicArguments => '...';
  String get underscore => '_';
  String get globals => '__globals__';
  String get externs => '__externs__';
  String get instance => '__instance_of_';
  String get instancePrefix => 'instance of ';
  String get constructFun => '__construct__';
  String get getFun => '__get__';
  String get setFun => '__set__';

  String get object => 'Object';
  String get unknown => '__unknown__';
  String get list => 'List';
  String get map => 'Map';
  String get length => 'length';
  String get function => 'function';
  String get method => 'method';
  String get identifier => 'identifier';

  String get TRUE => 'true';
  String get FALSE => 'false';
  String get NULL => 'null';

  String get VOID => 'void';
  String get VAR => 'var';
  String get LET => 'let';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  String get ANY => 'any';
  String get TYPEDEF => 'typedef';

  String get STATIC => 'static';
  // static const CONST => 'const';
  String get FINAL => 'final';
  String get CONSTRUCT => 'construct';
  String get GET => 'get';
  String get SET => 'set';
  //static const Final => 'final';
  String get NAMESPACE => 'namespace';
  String get AS => 'as';
  String get ABSTRACT => 'abstract';
  String get CLASS => 'class';
  String get STRUCT => 'struct';
  String get UNION => 'union';
  String get FUN => 'fun';
  String get Arguments => 'arguments';
  String get THIS => 'this';
  String get SUPER => 'super';
  String get EXTENDS => 'extends';
  String get IMPLEMENTS => 'implements';
  String get MIXIN => 'mixin';
  String get EXTERNAL => 'external';
  String get LIBRARY => 'library';
  String get IMPORT => 'import';

  String get Assert => 'assert';
  String get BREAK => 'break';
  String get CONTINUE => 'continue';
  String get FOR => 'for';
  String get IN => 'in';
  String get IF => 'if';
  String get ELSE => 'else';
  String get RETURN => 'return';
  String get THROW => 'throw';
  String get WHILE => 'while';
  String get DO => 'do';
  String get WHEN => 'when';
  String get TRY => 'try';
  String get CATCH => 'catch';
  String get FINALLY => 'finally';

  String get IS => 'is';

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
        ABSTRACT,
        CLASS,
        FUN,
        CONSTRUCT,
        GET,
        SET,
        THIS,
        SUPER,
        EXTENDS,
        IMPLEMENTS,
        MIXIN,
        EXTERNAL,
        LIBRARY,
        IMPORT,
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
        IS,
      };

  /// 函数调用表达式
  String get nullExpr => 'null_expression';
  String get literalExpr => 'literal_expression';
  String get groupExpr => 'group_expression';
  String get vectorExpr => 'vector_expression';
  String get blockExpr => 'block_expression';
  String get varExpr => 'variable_expression';
  String get typeExpr => 'type_expression';
  String get unaryExpr => 'unary_expression';
  String get binaryExpr => 'binary_expression';
  String get callExpr => 'call_expression';
  String get thisExpr => 'this_expression';
  String get assignExpr => 'assign_expression';
  String get subGetExpr => 'subscript_get_expression';
  String get subSetExpr => 'subscript_set_expression';
  String get memberGetExpr => 'member_get_expression';
  String get memberSetExpr => 'member_set_expression';

  String get importStmt => 'import_statement';
  String get varStmt => 'variable_statement';
  String get exprStmt => 'expression_statement';
  String get blockStmt => 'block_statement';
  String get returnStmt => 'return_statement';
  String get breakStmt => 'break_statement';
  String get continueStmt => 'continue_statement';
  String get ifStmt => 'if_statement';
  String get whileStmt => 'while_statement';
  String get forInStmt => 'for_in_statement';
  String get classStmt => 'class_statement';
  String get funcStmt => 'function_statement';
  String get externFuncStmt => 'external_function_statement';
  String get constructorStmt => 'constructor_function_statement';

  String get memberGet => '.';
  String get subGet => '[';
  String get call => '(';

  /// 后缀操作符，包含多个符号
  Set<String> get unaryPostfixs => {
        memberGet,
        subGet,
        call,
      };

  String get not => '!';
  String get negative => '-';

  /// 前缀操作符，包含多个符号
  Set<String> get unaryPrefixs => {
        not,
        negative,
      };

  String get multiply => '*';
  String get devide => '/';
  String get modulo => '%';

  /// 乘除操作符，包含多个符号
  Set<String> get multiplicatives => {
        multiply,
        devide,
        modulo,
      };

  String get add => '+';
  String get subtract => '-';

  /// 加减操作符，包含多个符号
  Set<String> get additives => {
        add,
        subtract,
      };

  String get greater => '>';
  String get greaterOrEqual => '>=>';
  String get lesser => '<';
  String get lesserOrEqual => '<=>';

  /// 大小判断操作符，包含多个符号
  Set<String> get relationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        IS,
      };

  String get equal => '=>=>';
  String get notEqual => '!=>';

  /// 相等判断操作符，包含多个符号
  Set<String> get equalitys => {
        equal,
        notEqual,
      };

  String get and => '&&';
  String get or => '||';

  String get assign => '=>';

  /// 赋值类型操作符，包含多个符号
  Set<String> get assignments => {
        assign,
      };

  String get comma => ',';
  String get colon => ':';
  String get semicolon => ';';
  String get roundLeft => '(';
  String get roundRight => ')';
  String get curlyLeft => '{';
  String get curlyRight => '}';
  String get squareLeft => '[';
  String get squareRight => ']';
  String get angleLeft => '<';
  String get angleRight => '>';

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

  String get errorUnsupport => 'Unsupport value type';
  String get errorExpected => 'expected, get';
  String get errorUnexpected => 'Unexpected identifier';
  String get errorPrivate => 'Could not acess private member';
  String get errorInitialized => 'has not initialized';
  String get errorUndefined => 'Undefined identifier';
  String get errorUndefinedOperator => 'Undefined operator';
  String get errorDeclared => 'is already declared';
  String get errorDefined => 'is already defined';
  String get errorRange => 'Index out of range, should be less than';
  String get errorInvalidLeftValue => 'Invalid left-value';
  String get errorCallable => 'is not callable';
  String get errorUndefinedMember => 'isn\'t defined for the class';
  String get errorCondition => 'Condition expression must evaluate to type "bool"';
  String get errorMissingFuncDef => 'Missing function definition body of';
  String get errorGet => 'is not a collection or object';
  String get errorSubGet => 'is not a List or Map';
  String get errorExtends => 'is not a class';
  String get errorSetter => 'Setter function\'s arity must be 1';
  String get errorNullObject => 'is null';
  String get errorMutable => 'is immutable';
  String get errorNotType => 'is not a type.';

  String get errorOfType => 'of type';

  String get errorType1 => 'Variable';
  String get errorType2 => 'can\'t be assigned with type';

  String get errorArgType1 => 'Argument';
  String get errorArgType2 => 'doesn\'t match parameter type';

  String get errorReturnType1 => 'Value of type';
  String get errorReturnType2 => 'can\'t be returned from function';
  String get errorReturnType3 => 'because it has a return type of';

  String get errorArity1 => 'Number of arguments';
  String get errorArity2 => 'doesn\'t match parameter requirement of function';
}

final regexCommandLine = RegExp(
  r'(//.*)|' // 注释 group(1)
  r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
  r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!:\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
  r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
  r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
  r'("(\\"|[^"])*"))',
  unicode: true,
  multiLine: true,
);
