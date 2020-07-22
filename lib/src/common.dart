abstract class HS_Common {
  static var coreLibPath = 'hetu_core';

  static var currentLanguage = enUS;

  static const zhHans = 'zh-Hans';
  static const enUS = 'en-US';
  static const commandLine = 'commandLine';

  static get pattern => patterns[currentLanguage];

  static final patterns = <String, RegExp>{
    enUS: RegExp(
      r'(//.*)|' // 注释 group(1)
      r'([_\p{L}][_\p{L}0-9]*)|' // 标识符 group(2)
      r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-!,;{}\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"('(\\'|\\\\|\\n|[^'])*')|", // 字符串字面量 group(6)
      unicode: true,
      multiLine: true,
    ),
    commandLine: RegExp(r'\S+'),
  };

  static const regCommentGrp = 1;
  static const regIdGrp = 2;
  static const regPuncGrp = 3;
  static const regNumGrp = 4;
  static const regStrGrp = 6;

  static const stringReplaces = <String, String>{
    r'\\\\': '\\',
    r'\\n': '\n',
    r"\\'": "'",
  };

  static const BuildInTypes = <String>[
    Dynamic,
    Var,
    Num,
    Bool,
    Str,
  ];

  static const ParametersTypes = <String>[
    Dynamic,
    Num,
    Bool,
    Str,
  ];

  static const FunctionReturnTypes = <String>[
    Void,
    Dynamic,
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

  static const Keywords = <String>[
    Null,
    Static,
    Const,
    Final,
    Namespace,
    As,
    Class,
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

  static const Var = 'var';
  static const Dynamic = 'dynamic';
  static const Num = 'num';
  static const Bool = 'bool';
  static const Str = 'String';
  static const Typedef = 'typedef';
  static const List = 'list';

  static const Null = 'null';
  static const Static = 'static';
  static const Const = 'const';
  static const Final = 'final';
  static const Namespace = 'namespace';
  static const As = 'as';
  static const Class = 'class';
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

  static const Constructor = 'constructor';
  static const New = 'new';

  static const Object = 'Object';

  /// 函数调用表达式
  static const LiteralExpr = 'literal_expression';
  static const ListOfNumExpr = 'list_of_num_expression';
  static const ListOfStringExpr = 'list_of_string_expression';
  static const ListOfDynamicExpr = 'list_of_dynamic_expression';
  static const MapExpr = 'map_expression';
  static const VarExpr = 'variable_expression';
  static const TypeExpr = 'type_expression';
  static const UnaryExpr = 'unary_expression';
  static const BinaryExpr = 'binary_expression';
  static const CallExpr = 'call_expression';
  static const NewExpr = 'new_expression';
  static const AssignExpr = 'assign_expression';
  static const SubGetExpr = 'subscript_get_expression';
  static const SubSetExpr = 'subscript_set_expression';
  static const MemberGetExpr = 'member_get_expression';
  static const MemberSetExpr = 'member_set_expression';

  static const VarStmt = 'variable_statement';
  static const ExprStmt = 'expression_statement';
  static const BlockStmt = 'block_statement';
  static const ReturnStmt = 'return_statement';
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
  ];
  static const Greater = '>';
  static const GreaterOrEqual = '>=';
  static const Lesser = '<';
  static const LesserOrEqual = '<=';

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

  static const Undefined = 'undefined';

  static const ErrorUnsupport = 'Unsupport value type';
  static const ErrorExpected = 'expected, get';
  static const ErrorUnexpected = 'Unexpected identifier';
  static const ErrorUndefined = 'Undefined variable';
  static const ErrorUndefinedOperator = 'Undefined operator';
  static const ErrorDefined = 'is already declared';
  static const ErrorRange = 'Index out of range, should be less than';
  static const ErrorInvalidLeftValue = 'Invalid left-value';
  static const ErrorCallable = 'is not callable';
  static const ErrorUndefinedMember = 'isn\'t defined for the class';
  static const ErrorCondition = 'Condition expression must evaluate to type "bool"';
  static const ErrorGet = 'is not a collection or object';
  static const ErrorExtends = 'is not a class';

  static const ErrorType1 = 'Assigned value type';
  static const ErrorType2 = 'doesn\'t match declared type';

  static const ErrorArgType1 = 'Argument value type';
  static const ErrorArgType2 = 'doesn\'t match parameter type';

  static const ErrorReturnType1 = 'Value of type';
  static const ErrorReturnType2 = 'can\'t be returned from function';
  static const ErrorReturnType3 = 'because it has a return type of';

  static const ErrorArity1 = 'Number of arguments';
  static const ErrorArity2 = 'doesn\'t match number of parameter';
}

// Hetu运算符优先级
// Description     Operator       Associativity   Precedence
//  Unary postfix   e., e()            None            16
//  Unary prefix    -e, !e         None            15
//  Multiplicative  *, /, %        Left            14
//  Additive        +, -           Left            13
//  Relational      <, >, <=, >=   None            8
//  Equality        ==, !=         None            7
//  Logical AND     &&             Left            6
//  Logical Or      ||             Left            5
//  Assignment      =              Right           1

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
