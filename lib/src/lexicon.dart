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

/// All lexicons used by hetu
abstract class HT_Lexicon {
  const HT_Lexicon();

  String get programEntrance;
  String get scriptPattern;

  Map<String, String> get stringReplaces;

  String convertStringLiteral(String literal) {
    var result = literal.substring(1).substring(0, literal.length - 2);
    for (final key in stringReplaces.keys) {
      result = result.replaceAll(key, stringReplaces[key]);
    }
    return result;
  }

  int get tokenGroupComment;
  int get tokenGroupIdentifier;
  int get tokenGroupPunctuation;
  int get tokenGroupNumber;
  int get tokenGroupString;

  String get number;
  String get boolean;
  String get string;

  Set<String> get literals => {
        number,
        boolean,
        string,
      };

  String get endOfFile; // 文件末尾
  String get newLine;
  String get multiline;
  String get variadicArguments;
  String get underscore;
  String get globals;
  String get externs;
  String get method;
  String get instance;
  String get instancePrefix;
  String get constructor;
  String get getter;
  String get setter;

  String get object;
  String get unknown;
  String get function;
  String get list;
  String get map;
  String get length;
  String get procedure;
  String get identifier;

  String get TRUE;
  String get FALSE;
  String get NULL;

  String get VOID;
  String get VAR;
  String get LET;
  String get CONST;
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  String get ANY;
  String get TYPEDEF;

  String get STATIC;
  String get INIT;
  String get GET;
  String get SET;
  String get NAMESPACE;
  String get ABSTRACT;
  String get CLASS;
  String get STRUCT;
  String get INTERFACE;
  String get FUN;
  String get ASYNC;
  String get THIS;
  String get SUPER;
  String get EXTENDS;
  String get IMPLEMENTS;
  String get MIXIN;
  String get EXTERNAL;
  String get IMPORT;

  String get AWAIT;
  String get ASSERT;
  String get BREAK;
  String get CONTINUE;
  String get FOR;
  String get IN;
  String get IF;
  String get ELSE;
  String get RETURN;
  String get WHILE;
  String get DO;
  String get WHEN;

  String get AS;
  String get IS;

  /// 保留字，不能用于变量名字
  Set<String> get keywords => {
        NULL,
        STATIC,
        VAR,
        LET,
        CONST,
        TYPEDEF,
        AS,
        CLASS,
        STRUCT,
        INTERFACE,
        FUN,
        ASYNC,
        AWAIT,
        VOID,
        INIT,
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
  String get nullExpr;
  String get literalExpr;
  String get groupExpr;
  String get vectorExpr;
  String get blockExpr;
  String get varExpr;
  String get typeExpr;
  String get unaryExpr;
  String get binaryExpr;
  String get callExpr;
  String get thisExpr;
  String get assignExpr;
  String get subGetExpr;
  String get subSetExpr;
  String get memberGetExpr;
  String get memberSetExpr;

  String get importStmt;
  String get varStmt;
  String get exprStmt;
  String get blockStmt;
  String get returnStmt;
  String get breakStmt;
  String get continueStmt;
  String get ifStmt;
  String get whileStmt;
  String get forInStmt;
  String get classStmt;
  String get funcStmt;
  String get externFuncStmt;
  String get constructorStmt;

  String get memberGet;
  String get subGet;
  String get call;

  /// 后缀操作符，包含多个符号
  Set<String> get unaryPostfixs => {
        memberGet,
        subGet,
        call,
      };

  String get not;
  String get negative;

  /// 前缀操作符，包含多个符号
  Set<String> get unaryPrefixs => {
        not,
        negative,
      };

  String get multiply;
  String get devide;
  String get modulo;

  /// 乘除操作符，包含多个符号
  Set<String> get multiplicatives => {
        multiply,
        devide,
        modulo,
      };

  String get add;
  String get subtract;

  /// 加减操作符，包含多个符号
  Set<String> get additives => {
        add,
        subtract,
      };

  String get greater;
  String get greaterOrEqual;
  String get lesser;
  String get lesserOrEqual;

  /// 大小判断操作符，包含多个符号
  Set<String> get relationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        IS,
      };

  String get equal;
  String get notEqual;

  /// 相等判断操作符，包含多个符号
  Set<String> get equalitys => {
        equal,
        notEqual,
      };

  String get and;
  String get or;

  String get assign;

  /// 赋值类型操作符，包含多个符号
  Set<String> get assignments => {
        assign,
      };

  String get comma;
  String get colon;
  String get semicolon;
  String get roundLeft;
  String get roundRight;
  String get curlyLeft;
  String get curlyRight;
  String get squareLeft;
  String get squareRight;
  String get angleLeft;
  String get angleRight;

  Set<String> get Punctuations => {
        not,
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
      };

  String get errorUnsupport;
  String get errorExpected;
  String get errorUnexpected;
  String get errorPrivateMember;
  String get errorPrivateDecl;
  String get errorInitialized;
  String get errorUndefined;
  String get errorUndefinedOperator;
  String get errorDeclared;
  String get errorDefined;
  String get errorRange;
  String get errorInvalidLeftValue;
  String get errorCallable;
  String get errorUndefinedMember;
  String get errorCondition;
  String get errorMissingFuncDef;
  String get errorGet;
  String get errorSubGet;
  String get errorExtends;
  String get errorSetter;
  String get errorNullObject;
  String get errorMutable;
  String get errorNotType;
  String get errorNotClass;
  String get errorOfType;
  String get errorType1;
  String get errorType2;
  String get errorArgType1;
  String get errorArgType2;
  String get errorReturnType1;
  String get errorReturnType2;
  String get errorReturnType3;
  String get errorArity1;
  String get errorArity2;
}

class HT_LexiconDefault extends HT_Lexicon {
  const HT_LexiconDefault();

  @override
  final programEntrance = 'main';

  @override
  final scriptPattern = r'((/\*[\s\S]*?\*/)|(//.*))|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(4)
      r'(\.\.\.|\|\||&&|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(5)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // 数字字面量 group(6)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(8)
      r'("(\\"|[^"])*"))';

  @override
  final stringReplaces = const <String, String>{
    '\\\\': '\\',
    '\\n': '\n',
    '\\\'': '\'',
  };

  @override
  final tokenGroupComment = 1;
  @override
  final tokenGroupIdentifier = 4;
  @override
  final tokenGroupPunctuation = 5;
  @override
  final tokenGroupNumber = 6;
  @override
  final tokenGroupString = 8;

  @override
  final number = 'num';
  @override
  final boolean = 'bool';
  @override
  final string = 'String';

  @override
  final endOfFile = 'end_of_file'; // 文件末尾
  @override
  final newLine = '\n';
  @override
  final multiline = '\\';
  @override
  final variadicArguments = '...';
  @override
  final underscore = '_';
  @override
  final globals = '__globals__';
  @override
  final externs = '__external__';
  @override
  final method = '__method__';
  @override
  final instance = '__instance_of_';
  @override
  final instancePrefix = 'instance of ';
  @override
  final constructor = '__init__';
  @override
  final getter = '__get__';
  @override
  final setter = '__set__';

  @override
  final object = 'Object';
  @override
  final unknown = '__unknown__';
  @override
  final function = 'function';
  @override
  final list = 'List';
  @override
  final map = 'Map';
  @override
  final length = 'length';
  @override
  final procedure = 'procedure';
  @override
  final identifier = 'identifier';

  @override
  final TRUE = 'true';
  @override
  final FALSE = 'false';
  @override
  final NULL = 'null';

  @override
  final VOID = 'void';
  @override
  final VAR = 'var';
  @override
  final LET = 'let';
  @override
  final CONST = 'const';
  @override
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  final ANY = 'any';
  @override
  final TYPEDEF = 'typedef';

  @override
  final STATIC = 'static';
  @override
  final INIT = 'init';
  @override
  final GET = 'get';
  @override
  final SET = 'set';
  @override
  final NAMESPACE = 'namespace';
  @override
  final ABSTRACT = 'abstract';
  @override
  final CLASS = 'class';
  @override
  final STRUCT = 'struct';
  @override
  final INTERFACE = 'interface';
  @override
  final FUN = 'fun';
  @override
  final ASYNC = 'async';
  @override
  final THIS = 'this';
  @override
  final SUPER = 'super';
  @override
  final EXTENDS = 'extends';
  @override
  final IMPLEMENTS = 'implements';
  @override
  final MIXIN = 'mixin';
  @override
  final EXTERNAL = 'external';
  @override
  final IMPORT = 'import';

  @override
  final AWAIT = 'await';
  @override
  final ASSERT = 'assert';
  @override
  final BREAK = 'break';
  @override
  final CONTINUE = 'continue';
  @override
  final FOR = 'for';
  @override
  final IN = 'in';
  @override
  final IF = 'if';
  @override
  final ELSE = 'else';
  @override
  final RETURN = 'return';
  @override
  final WHILE = 'while';
  @override
  final DO = 'do';
  @override
  final WHEN = 'when';

  @override
  final AS = 'as';
  @override
  final IS = 'is';

  /// 函数调用表达式
  @override
  final nullExpr = 'null_expression';
  @override
  final literalExpr = 'literal_expression';
  @override
  final groupExpr = 'group_expression';
  @override
  final vectorExpr = 'vector_expression';
  @override
  final blockExpr = 'block_expression';
  @override
  final varExpr = 'variable_expression';
  @override
  final typeExpr = 'type_expression';
  @override
  final unaryExpr = 'unary_expression';
  @override
  final binaryExpr = 'binary_expression';
  @override
  final callExpr = 'call_expression';
  @override
  final thisExpr = 'this_expression';
  @override
  final assignExpr = 'assign_expression';
  @override
  final subGetExpr = 'subscript_get_expression';
  @override
  final subSetExpr = 'subscript_set_expression';
  @override
  final memberGetExpr = 'member_get_expression';
  @override
  final memberSetExpr = 'member_set_expression';

  @override
  final importStmt = 'import_statement';
  @override
  final varStmt = 'variable_statement';
  @override
  final exprStmt = 'expression_statement';
  @override
  final blockStmt = 'block_statement';
  @override
  final returnStmt = 'return_statement';
  @override
  final breakStmt = 'break_statement';
  @override
  final continueStmt = 'continue_statement';
  @override
  final ifStmt = 'if_statement';
  @override
  final whileStmt = 'while_statement';
  @override
  final forInStmt = 'for_in_statement';
  @override
  final classStmt = 'class_statement';
  @override
  final funcStmt = 'function_statement';
  @override
  final externFuncStmt = 'external_function_statement';
  @override
  final constructorStmt = 'constructor_function_statement';

  @override
  final memberGet = '.';
  @override
  final subGet = '[';
  @override
  final call = '(';

  @override
  final not = '!';
  @override
  final negative = '-';
  @override
  final multiply = '*';
  @override
  final devide = '/';
  @override
  final modulo = '%';
  @override
  final add = '+';
  @override
  final subtract = '-';
  @override
  final greater = '>';
  @override
  final greaterOrEqual = '>=';
  @override
  final lesser = '<';
  @override
  final lesserOrEqual = '<=';
  @override
  final equal = '==';
  @override
  final notEqual = '!=';
  @override
  final and = '&&';
  @override
  final or = '||';
  @override
  final assign = '=';

  @override
  final comma = ',';
  @override
  final colon = ':';
  @override
  final semicolon = ';';
  @override
  final roundLeft = '(';
  @override
  final roundRight = ')';
  @override
  final curlyLeft = '{';
  @override
  final curlyRight = '}';
  @override
  final squareLeft = '[';
  @override
  final squareRight = ']';
  @override
  final angleLeft = '<';
  @override
  final angleRight = '>';

  @override
  final errorUnsupport = 'Unsupport value type';
  @override
  final errorExpected = 'expected, ';
  @override
  final errorUnexpected = 'Unexpected identifier';
  @override
  final errorPrivateMember = 'Could not acess private member';
  @override
  final errorPrivateDecl = 'Could not acess private declaration';
  @override
  final errorInitialized = 'has not initialized';
  @override
  final errorUndefined = 'Undefined identifier';
  @override
  final errorUndefinedOperator = 'Undefined operator';
  @override
  final errorDeclared = 'is already declared';
  @override
  final errorDefined = 'is already defined';
  @override
  final errorRange = 'Index out of range, should be less than';
  @override
  final errorInvalidLeftValue = 'Invalid left-value';
  @override
  final errorCallable = 'is not callable';
  @override
  final errorUndefinedMember = 'isn\'t defined for the class';
  @override
  final errorCondition = 'Condition expression must evaluate to type "bool"';
  @override
  final errorMissingFuncDef = 'Missing function definition body of';
  @override
  final errorGet = 'is not a collection or object';
  @override
  final errorSubGet = 'is not a List or Map';
  @override
  final errorExtends = 'is not a class';
  @override
  final errorSetter = 'Setter function\'s arity must be 1';
  @override
  final errorNullObject = 'is null';
  @override
  final errorMutable = 'is immutable';
  @override
  final errorNotType = 'is not a type.';
  @override
  final errorNotClass = 'is not a class.';
  @override
  final errorOfType = 'of type';
  @override
  final errorType1 = 'Variable';
  @override
  final errorType2 = 'can\'t be assigned with type';
  @override
  final errorArgType1 = 'Argument';
  @override
  final errorArgType2 = 'doesn\'t match parameter type';
  @override
  final errorReturnType1 = 'Value of type';
  @override
  final errorReturnType2 = 'can\'t be returned from function';
  @override
  final errorReturnType3 = 'because it has a return type of';
  @override
  final errorArity1 = 'Number of arguments';
  @override
  final errorArity2 = 'doesn\'t match parameter requirement of function';
}
