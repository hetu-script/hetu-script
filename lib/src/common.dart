abstract class HS_LexPatterns {
  static final enUS = RegExp(
    r'(//.*)|' // 注释 group(1)
    r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
    r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
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
    "\\'": "'",
  };

  static String convertEscapeCode(String line) {
    for (var key in _stringReplaces.keys) {
      line = line.replaceAll(key, _stringReplaces[key]);
    }
    return line;
  }

  static const BuildInTypes = <String>[
    Dynamic,
    Var,
    Num,
    Bool,
    Str,
  ];

  static const Literals = <String>[
    Bool,
    Num,
    Str,
    Null,
    //Array,
    //Dict,
  ];

  /// 保留字，不能用于变量名字
  static const Keywords = <String>[
    Null,
    Static,
    Const,
    Final,
    Var,
    Namespace,
    As,
    Abstract,
    Class,
    Func,
    Arguments,
    Init,
    Get,
    Set,
    This,
    Super,
    Extends,
    Implements,
    Mixin,
    External,
    Import,
    Assert,
    Break,
    Continue,
    For,
    In,
    If,
    Else,
    Return,
    Throw,
    While,
    Do,
    Try,
    Catch,
    Finally,
    Switch,
    Case,
    Default,
    New,
    Is,
  ];

  static const Punctuations = <String>[
    Not,
    Multiply,
    Devide,
    Modulo,
    Add,
    Subtract,
    Greater,
    GreaterOrEqual,
    Lesser,
    LesserOrEqual,
    Equal,
    NotEqual,
    And,
    Or,
    Assign,
    Comma,
    Colon,
    Semicolon,
    Dot,
    RoundLeft,
    RoundRight,
    CurlyLeft,
    CurlyRight,
    SquareLeft,
    SquareRight,
    AngleLeft,
    AngleRight,
  ];

  static const EOF = 'end_of_file'; // 文件末尾
  static const Void = 'void';
  static const Unknown = '?';
  static const Underscore = '_';
  static const Global = '__global__';
  static const Extern = '__extern__';
  static const Instance = '__instance__';
  static const InstanceString = 'instance of class ';

  static const UnknownType = 'unknown_type';
  static const Var = 'var';
  static const Dynamic = 'dynamic';
  static const Num = 'num';
  static const Bool = 'bool';
  static const Str = 'String';
  static const Typedef = 'typedef';
  static const List = 'List';
  static const ListOfNum = 'list_of_num';
  static const ListOfString = 'list_of_string';
  static const ListOfDynamic = 'list_of_dynamic';
  static const Map = 'Map';

  static const Null = 'null';
  static const Static = 'static';
  static const Const = 'const';
  static const Init = 'init';
  static const Initter = '_init_';
  static const Get = 'get';
  static const Getter = '_get_';
  static const Set = 'set';
  static const Setter = '_set_';
  static const Final = 'final';
  static const Namespace = 'namespace';
  static const As = 'as';
  static const Abstract = 'abstract';
  static const Class = 'class';
  static const Func = 'func';
  static const Arguments = 'arguments';
  static const Function = 'Function';
  static const Method = 'method';
  static const This = 'this';
  static const Super = 'super';
  static const Extends = 'extends';
  static const Implements = 'implements';
  static const Mixin = 'mixin';
  static const External = 'external';
  static const Import = 'import';

  static const Assert = 'assert';
  static const Break = 'break';
  static const Continue = 'continue';
  static const For = 'for';
  static const In = 'in';
  static const If = 'if';
  static const Else = 'else';
  static const Return = 'return';
  static const Throw = 'throw';
  static const While = 'while';
  static const Do = 'do';
  static const Try = 'try';
  static const Catch = 'catch';
  static const Finally = 'finally';
  static const Switch = 'switch';
  static const Case = 'case';
  static const Default = 'default';

  static const True = 'true';
  static const False = 'false';

  static const New = 'new';

  static const Object = 'Object';

  /// 函数调用表达式
  static const NullExpr = 'null_expression';
  static const LiteralExpr = 'literal_expression';
  static const ListExpr = 'list_expression';
  static const MapExpr = 'map_expression';
  static const VarExpr = 'variable_expression';
  static const GroupExpr = 'group_expression';
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
  static const UnaryPostfix = <String>[
    Dot,
    RoundLeft,
    SquareLeft,
  ];

  /// 前缀操作符，包含多个符号
  static const UnaryPrefix = <String>[
    Not,
    Subtract,
  ];
  static const Not = '!';

  /// 乘除操作符，包含多个符号
  static const Multiplicative = <String>[
    Multiply,
    Devide,
    Modulo,
  ];
  static const Multiply = '*';
  static const Devide = '/';
  static const Modulo = '%';

  /// 加减操作符，包含多个符号
  static const Additive = <String>[
    Add,
    Subtract,
  ];
  static const Add = '+';
  static const Subtract = '-';

  /// 大小判断操作符，包含多个符号
  static const Relational = <String>[
    Greater,
    GreaterOrEqual,
    Lesser,
    LesserOrEqual,
    Is,
  ];
  static const Greater = '>';
  static const GreaterOrEqual = '>=';
  static const Lesser = '<';
  static const LesserOrEqual = '<=';
  static const Is = 'is';

  /// 相等判断操作符，包含多个符号
  static const Equality = <String>[
    Equal,
    NotEqual,
  ];
  static const Equal = '==';
  static const NotEqual = '!=';

  static const And = '&&';
  static const Or = '||';

  /// 赋值类型操作符，包含多个符号
  static const Assignment = <String>[
    Assign,
  ];
  static const Assign = '=';

  static const Identifier = 'identifier'; // 标识符

  static const Comma = ',';
  static const Colon = ':';
  static const Semicolon = ';';
  static const Dot = '.';
  static const RoundLeft = '(';
  static const RoundRight = ')';
  static const CurlyLeft = '{';
  static const CurlyRight = '}';
  static const SquareLeft = '[';
  static const SquareRight = ']';
  static const AngleLeft = '<';
  static const AngleRight = '>';

  static const length = 'length';

  static const Undefined = 'undefined';

  static const ErrorUnsupport = 'Unsupport value type';
  static const ErrorExpected = 'expected, get';
  static const ErrorUnexpected = 'Unexpected identifier';
  static const ErrorPrivate = 'Could not acess private member';
  static const ErrorInitialized = 'has not initialized';
  static const ErrorUndefined = 'Undefined identifier';
  static const ErrorUndefinedOperator = 'Undefined operator';
  static const ErrorDeclared = 'is already declared';
  static const ErrorDefined = 'is already defined';
  static const ErrorRange = 'Index out of range, should be less than';
  static const ErrorInvalidLeftValue = 'Invalid left-value';
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

  static const ErrorType1 = 'Assigned value type';
  static const ErrorType2 = 'doesn\'t match declared type';

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
