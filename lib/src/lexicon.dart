/// All lexicons used by hetu
abstract class HTLexicon {
  static const defaultProgramMainFunc = 'main';

  static const scriptPattern = r'((/\*[\s\S]*?\*/)|(//.*))|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(4)
      r'(\.\.\.|\|\||&&|\+\+|--|\*=|/=|\+=|-=|==|!=|<=|>=|->|=>|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(5)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // 数字字面量 group(6)
      // r'(\d+\.\d+)|' // 浮点数字面量 group(6)
      // r'((?<![\d.])[0-9]+(?![\d.]))|' // 整数字面量 group(7)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(8)
      r'("(\\"|[^"])*"))';

  /// Add semicolon before a line starting with one of '++, --, (, ['
  static const Set<String> ASIStart = {
    roundLeft,
    preIncrement,
    preDecrement,
  };

  /// Add semicolon after a line with 'return'
  static const Set<String> ASIEnd = {
    RETURN,
  };

  static const tokenGroupComment = 1;
  static const tokenGroupIdentifier = 4;
  static const tokenGroupPunctuation = 5;
  static const tokenGroupNumber = 6;
  static const tokenGroupFloat = 6;
  static const tokenGroupInt = 7;
  static const tokenGroupString = 8;

  static const object = 'object';
  static const boolean = 'bool';
  static const number = 'num';
  static const integer = 'int';
  static const float = 'float';
  static const dartFloat = 'double';
  static const string = 'str';
  static const dartString = 'String';
  static const list = 'List';
  static const map = 'Map';
  static const jsonObject = 'JSON Object';
  static const rtType = 'runtimeType';
  static const keys = 'keys';
  static const values = 'values';
  static const first = 'first';
  static const last = 'last';
  static const length = 'length';
  static const isEmpty = 'isEmpty';
  static const isNotEmpty = 'isNotEmpty';
  static const elementAt = 'elementAt';
  static const parse = 'parse';

  static const Set<String> literals = {
    number,
    boolean,
    string,
  };

  static const endOfFile = 'end_of_file'; // 文件末尾
  static const multiline = '\\';
  static const varargs = '...'; // variadic arguments
  static const singleQuotation = "'";
  static const doubleQuotation = '"';
  static const anonymousScript = '\$_anonymousScript_';
  static const anonymousFunction = '\$_anonymousFunction_';
  static const anonymousNamespace = '\$_anonymousNamespace_';
  static const anonymousBlock = '\$_anonymousBlock_';
  static const increment = '\$_increment_';
  static const functionCall = 'call';
  static const underscore = '_';
  static const global = 'global';
  static const unknownType = 'unknown type';
  static const instance = '\$_instance_';
  static const constructor = '\$_constructor_';
  static const getter = '\$_getter_';
  static const setter = '\$_setter_';

  static const instanceOf = 'instance of';
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

  static const typesBracketLeft = '<';
  static const typesBracketRight = '>';
  static const arrow = '->';
  static const bigarrow = '=>';

  static const TYPE = 'type';
  static const VOID = 'void';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  static const ANY = 'any';

  static const Set<String> primitiveType = {
    TYPE,
    ANY,
    NULL,
    VOID,
    CLASS,
    ENUM,
    NAMESPACE,
    FUNCTION,
    unknownType,
    object,
  };

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
  static const FUNCTION = 'fun';
  static const ASYNC = 'async';
  static const THIS = 'this';
  static const SUPER = 'super';
  static const ABSTRACT = 'abstract';
  static const EXTENDS = 'extends';
  static const IMPLEMENTS = 'implements';
  static const EXTERNAL = 'external';
  static const IMPORT = 'import';

  static const MIXIN = 'mixin';

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
    IMPORT,
    EXTERNAL,
    ABSTRACT,
    STATIC,
    VAR,
    LET,
    FINAL,
    CONST,
    CLASS,
    ENUM,
    STRUCT,
    CONSTRUCT,
    GET,
    SET,
    FUNCTION,
    ASYNC, // TODO: async单独可以用作函数声明关键字
    AWAIT,
    VOID,
    EXTENDS,
    IMPLEMENTS,
    MIXIN,
    THIS,
    SUPER,
    BREAK,
    CONTINUE,
    RETURN,
    FOR,
    IN,
    IF,
    ELSE,
    WHILE,
    DO,
    WHEN,
    IS,
    AS,
  };

  /// 可以用作变量名字的关键字
  static const Set<String> otherKeywords = {};

  /// 函数调用表达式
  static const expression = 'expression';
  static const statement = 'statement';
  static const declStmt = 'declaration_statement';
  static const thenBranch = 'then_branch';
  static const elseBranch = 'else_branch';

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
    AS,
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
  static const condition = '?';

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

  static const Set<String> unfinishedTokens = {
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
    memberGet,
    roundLeft,
    curlyLeft,
    squareLeft,
    comma,
    colon,
  };

  static const Set<String> punctuations = {
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
    memberGet,
    roundLeft,
    roundRight,
    curlyLeft,
    curlyRight,
    squareLeft,
    squareRight,
    comma,
    colon,
    semicolon,
  };

  static const math = 'Math';
  static const system = 'System';
  static const console = 'Console';

  static const errorUnexpected = '[{0}] expected, met [{1}].';
  static const errorConstMustBeStatic =
      'Constant class member [{0}] must also be declared as static.';
  static const errorConstMustInit =
      'Constant declaration [{0}] must be initialized.';
  static const errorDefined = '[{0}] is already defined.';
  static const errorInvalidLeftValue = 'Illegal left value.';
  static const errorOutsideReturn =
      'Unexpected return statement outside of a function.';
  static const errorOutsideThis =
      'Unexpected this expression outside of a function.';
  static const errorSetterArity =
      'Setter function must have exactly one parameter.';
  static const errorExternMember =
      'Non-external class cannot have non-static external members.';
  static const errorEmptyTypeArgs = 'Empty type arguments.';
  static const errorNotMember = '[{0}] is not a class member of [{1}].';
  static const errorNotClass = '[{0}] is not a class.';
  static const errorExtendsSelf = 'Class try to extends itself.';
  static const errorCtorReturn = 'Constructor cannot have a return type.';
  static const errorAbstracted = 'Cannot create instance from abstract class.';
  static const errorAbstractCtor =
      'Cannot create contructor for abstract class.';

  static const errorUnknownOpCode = 'Unknown opcode [{0}]';
  static const errorPrivateMember = 'Could not acess private member [{0}].';
  static const errorPrivateDecl = 'Could not acess private declaration [{0}].';
  static const errorNotInitialized = '[{0}] has not yet been initialized.';
  static const errorUndefined = 'Undefined identifier [{0}].';
  static const errorUndefinedExtern = 'Undefined external identifier [{0}].';
  static const errorUnknownTypeName = 'Unknown type name: [{0}].';
  static const errorUndefinedOperator = 'Undefined operator: [{0}].';
  // static const errorRange = 'Index out of range, should be less than';
  static const errorNotCallable = '[{0}] is not callable.';
  static const errorUndefinedMember = '[{0}] isn\'t defined for the class.';
  static const errorCondition =
      'Condition expression must evaluate to type [bool]';
  static const errorNotList = '[{0}] is not a List or Map.';
  static const errorNullObject = 'Calling method on null object: [{0}]';
  static const errorNullable = '[{0}] is not nullable.';
  static const errorType = 'Variable [{0}] can\'t be assigned with type [{1}].';
  static const errorImmutable = '[{0}] is immutable.';
  static const errorNotType = '[{0}] is not a type.';
  static const errorArgType =
      'Argument [{0}] of type [{1}] doesn\'t match parameter type [{2}].';
  static const errorReturnType =
      '[{0}] can\'t be returned from function [{1}] with return type [{2}].';
  static const errorMissingFuncBody = 'Missing function definition of [{0}].';
  static const errorArity =
      'Number of arguments [{0}] doesn\'t match function [{1}]\'s parameter requirement [{2}].';
  static const errorBinding = 'Missing binding extension on dart object';
  static const errorExternalVar = 'External variable is not allowed.';
  static const errorBytesSig = 'Unknown bytecode signature.';
  static const errorCircleInit =
      'Variable [{0}]\'s initializer depend on itself being initialized.';
  static const errorInitialize = 'Missing variable initializer.';
  static const errorNamedArg = 'Undefined named parameter: [{0}]';
  static const errorIterable = '[{0}] is not Iterable.';
  static const errorUnkownValueType = 'Unkown OpCode value type: [{0}].';
  static const errorEmptyString = 'Unexpected empty string content. {0}';
  static const errorTypeCast = '[{0}]\'s type cannot be cast into [{1}].';
  static const errorCastee = 'Illegal cast target [{0}].';
  static const errorClone = 'Illegal clone on [{0}].';
  static const errorNotSuper = '[{0}] is not a super class of [{1}].';
  static const errorMissingExternalFuncDef =
      'Missing external function definition of [{0}].';
  static const errorInternalFuncWithExternalTypeDef =
      'Unexpected external typedef on internal function.';
  static const errorExternalCtorWithReferCtor =
      'Unexpected refer constructor on external constructor.';
  static const errorNonCotrWithReferCtor =
      'Unexpected refer constructor on normal function.';
  static const errorModuleImport = 'Module import handler error on file: [{0}]';
  static const errorClassOnInstance = 'Try to define a class on instance.';
}
