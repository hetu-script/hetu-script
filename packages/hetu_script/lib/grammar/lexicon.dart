/// All lexicons used by hetu
abstract class HTLexicon {
  static const tokenPattern =
      r'((//.*)|(/\*[\s\S]*\*/))|' // comment group(2 & 3)
      r'(([_\$\p{L}]+[_\$\p{L}0-9]*)|([_]+))|' // unicode identifier group(4)
      r'(\.\.\.|~/=|\?\?=|\?\?|\|\||&&|\+\+|--|\*=|/=|\+=|-=|==|!=|<=|>=|->|=>|\?\.|\?\[|\?\(|~/|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // punctuation group(7)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // number group(8)
      r"('(\\'|[^'])*(\$\{[^\$\{\}]*\})+(\\'|[^'])*')|" // interpolation string with single quotation mark group(10)
      r'("(\\"|[^"])*(\$\{[^\$\{\}]*\})+(\\"|[^"])*")|' // interpolation string with double quotation mark group(14)
      r"('(\\'|[^'])*')|" // string with single quotation mark group(18)
      r'("(\\"|[^"])*")|' // string with double quotation mark group(20)
      r'(`(\\`|[^`])*`)'; // string with grave accent mark group(22)

  static const tokenGroupSingleComment = 2;
  static const tokenGroupBlockComment = 3;
  static const tokenGroupIdentifier = 4;
  static const tokenGroupPunctuation = 7;
  static const tokenGroupNumber = 8;
  static const tokenGroupApostropheStringInterpolation = 10;
  static const tokenGroupQuotationStringInterpolation = 14;
  static const tokenGroupApostropheString = 18;
  static const tokenGroupQuotationString = 20;
  static const tokenGroupStringGraveAccent = 22;

  static const singleLineCommentDocumentationPattern = r'///';
  static const multiLineCommentDocumentationPattern = r'/**';

  static const libraryNamePattern = r"(library '((\\'|[^'])*)')|"
      r'(library "((\\"|[^"])*)")';

  static const libraryNameSingleMark = 2;
  static const libraryNameDoubleMark = 5;

  static const stringInterpolationPattern = r'\${([^\${}]*)}';
  static const stringInterpolationStart = r'${';
  static const stringInterpolationEnd = r'}';

  static const stringEscapes = <String, String>{
    r'\\': '\\',
    r"\'": '\'',
    r'\"': '"',
    r'\`': '`',
    r'\n': '\n',
    r'\t': '\t',
  };

  /// Add semicolon before a line starting with one of '{, (, [, ++, --'.
  /// This is to avoid ambiguity in parser.
  static const Set<String> defaultSemicolonStart = {
    bracesLeft,
    parenthesesLeft,
    bracketsLeft,
    preIncrement,
    preDecrement,
  };

  /// Add semicolon after a line with 'return'
  static const Set<String> defaultSemicolonEnd = {
    kReturn,
  };

  static const main = 'main';
  static const instanceof = 'instance of';

  static const boolean = 'bool';
  static const number = 'num';
  static const integer = 'int';
  static const float = 'float';
  static const string = 'str';

  static const values = 'values';
  static const iterator = 'iterator';
  static const moveNext = 'moveNext';
  static const current = 'current';
  static const parse = 'parse';
  static const contains = 'contains';
  static const tostring = 'toString';

  static const scriptStackTrace = 'Hetu stack trace';
  static const externalStackTrace = 'Dart stack trace';

  static const variadicArgs = '...';
  static const privatePrefix = '_';
  static const privatePrefix2 = r'#';

  /// '$'
  static const internalPrefix = r'$';
  static const percentageMark = r'%';
  static const typesBracketLeft = '<';
  static const typesBracketRight = '>';
  static const singleArrow = '->';
  static const doubleArrow = '=>';
  static const decimalPoint = '.';
  static const indentSpaces = '  ';
  static const spreadSyntax = '...';

  static const kNull = 'null';
  static const kTrue = 'true';
  static const kFalse = 'false';

  static const kVar = 'var';
  static const kFinal = 'final';
  static const kLate = 'late';
  static const kConst = 'const';
  static const kDefine = 'def';
  static const kDelete = 'delete';

  /// 变量声明
  static const Set<String> varDeclKeywords = {
    kVar,
    kFinal,
    kConst,
  };

  static const Set<String> primitiveTypes = {
    kType,
    kAny,
    kVoid,
    kUnknown,
    kNever,
    // FUNCTION,
  };

  static const kVoid = 'void';
  static const kAny = 'any';
  static const kUnknown = 'unknown';
  static const kNever = 'never';
  static const kFunction = 'function';

  static const kType = 'type';
  static const object = 'object';
  static const prototype = 'prototype';
  static const library = 'library';
  static const asterisk = '*';
  static const kImport = 'import';
  static const kExport = 'export';
  static const kFrom = 'from';

  static const kAssert = 'assert';
  static const kTypeof = 'typeof';
  static const kAs = 'as';
  static const kNamespace = 'namespace';
  static const kClass = 'class';
  static const kEnum = 'enum';
  static const kFun = 'fun';
  static const kStruct = 'struct';
  static const kInterface = 'inteface';
  static const kThis = 'this';
  static const kSuper = 'super';

  static const Set<String> constructorCall = {kThis, kSuper};

  static const kAbstract = 'abstract';
  static const kOverride = 'override';
  static const kExternal = 'external';
  static const kStatic = 'static';
  static const kExtends = 'extends';
  static const kImplements = 'implements';
  static const kWith = 'with';
  static const kRequired = 'required';
  static const kReadonly = 'readonly';

  static const kConstruct = 'construct';
  static const kFactory = 'factory';
  static const kGet = 'get';
  static const kSet = 'set';
  static const kAsync = 'async';
  static const bind = 'bind';
  static const apply = 'apply';

  static const kAwait = 'await';
  static const kBreak = 'break';
  static const kContinue = 'continue';
  static const kReturn = 'return';
  static const kFor = 'for';
  static const kIn = 'in';
  static const kNotIn = 'in!';
  static const kOf = 'of';
  static const kIf = 'if';
  static const kElse = 'else';
  static const kWhile = 'while';
  static const kDo = 'do';
  static const kWhen = 'when';
  static const kIs = 'is';
  static const kIsNot = 'is!';

  static const kTry = 'try';
  static const kCatch = 'catch';
  static const kFinally = 'finally';
  static const kThrow = 'throw';

  /// 内置关键字
  static const Set<String> keywords = {
    kNull,
    kTrue,
    kFalse,
    kVar,
    kFinal,
    kLate,
    kConst,
    // kDefine,
    kDelete,
    kAssert,
    kTypeof,
    kNamespace,
    kClass,
    kEnum,
    kFun,
    kStruct,
    // kInterface,
    kThis,
    kSuper,
    kAbstract,
    kOverride,
    kExternal,
    kStatic,
    kExtends,
    kImplements,
    kWith,
    kConstruct,
    kFactory,
    kGet,
    kSet,
    kAsync, // TODO: async单独可以用作函数声明关键字
    kAwait,
    kBreak,
    kContinue,
    kReturn,
    kFor,
    kIn,
    kIf,
    kElse,
    kWhile,
    kDo,
    kWhen,
    kIs,
    kAs,
    // kTry,
    // kCatch,
    // kFinally,
    kThrow,
  };

  static const Set<String> contextualKeyword = {
    kOf,
    kVoid,
    kType,
    kImport,
    kExport,
    kAny,
    kUnknown,
    kNever,
    kFrom,
    kRequired,
    kReadonly,
  };

  static const nullableMemberGet = '?.';
  static const memberGet = '.';
  static const nullableSubGet = '?[';
  static const subGet = '[';
  static const nullableCall = '?(';
  static const call = '(';
  static const nullable = '?';
  static const postIncrement = '++';
  static const postDecrement = '--';

  /// 后缀操作符，包含多个符号
  static const Set<String> unaryPostfixs = {
    nullableMemberGet,
    memberGet,
    nullableSubGet,
    subGet,
    nullableCall,
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
    kTypeof,
  };

  static const multiply = '*';
  static const devide = '/';
  static const truncatingDevide = '~/';
  static const modulo = '%';

  /// 乘除操作符，包含多个符号
  static const Set<String> multiplicatives = {
    multiply,
    devide,
    truncatingDevide,
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
    kAs,
    kIs
    // is! is handled in parser
  };

  static const Set<String> logicalRelationals = {
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
  };

  static const Set<String> typeRelationals = {kAs, kIs};

  static const Set<String> setRelationals = {kIn};

  static const equal = '==';
  static const notEqual = '!=';

  /// 相等判断操作符，包含多个符号
  static const Set<String> equalitys = {
    equal,
    notEqual,
  };

  static const ifNull = '??';
  static const logicalOr = '||';
  static const logicalAnd = '&&';
  static const condition = '?';
  static const elseBranch = ':';

  static const assign = '=';
  static const assignAdd = '+=';
  static const assignSubtract = '-=';
  static const assignMultiply = '*=';
  static const assignDevide = '/=';
  static const assignTruncatingDevide = '~/=';
  static const assignIfNull = '??=';

  /// 赋值类型操作符，包含多个符号
  static const Set<String> assignments = {
    assign,
    assignAdd,
    assignSubtract,
    assignMultiply,
    assignDevide,
    assignTruncatingDevide,
    assignIfNull,
  };

  /// ','
  static const comma = ',';

  /// ':'
  static const colon = ':';

  /// ';'
  static const semicolon = ';';

  /// "'"
  static const apostropheLeft = "'";

  /// "'"
  static const apostropheRight = "'";

  /// '"'
  static const quotationLeft = '"';

  /// '"'
  static const quotationRight = '"';

  /// '('
  static const parenthesesLeft = '(';

  /// ')'
  static const parenthesesRight = ')';

  /// '{'
  static const bracesLeft = '{';

  /// '}'
  static const bracesRight = '}';

  /// '['
  static const bracketsLeft = '[';

  /// ']'
  static const bracketsRight = ']';

  /// '<'
  static const chevronsLeft = '<';

  /// '>'
  static const chevronsRight = '>';

  static const errorBytecode = 'Unrecognizable bytecode.';
  static const errorVersion =
      'Incompatible version - bytecode: [{0}], interpreter: [{1}].';
  static const errorAssertionFailed = "Assertion failed on '{0}'.";
  static const errorUnkownSourceType = 'Unknown source type: [{0}].';
  static const errorImportListOnNonHetuSource =
      'Cannot import list from a non hetu source.';
  static const errorExportNonHetuSource = 'Cannot export a non hetu source.';

  // syntactic errors
  static const errorUnexpected = 'Expected [{0}], met [{1}].';
  static const errorDelete =
      'Can only delete a local variable or a struct member.';
  static const errorExternal = 'External [{0}] is not allowed.';
  static const errorNestedClass = 'Nested class within another nested class.';
  static const errorConstInClass = 'Const value in class must be also static.';
  static const errorOutsideReturn =
      'Unexpected return statement outside of a function.';
  static const errorSetterArity =
      'Setter function must have exactly one parameter.';
  static const errorExternalMember =
      'Non-external class cannot have non-static external members.';
  static const errorEmptyTypeArgs = 'Empty type arguments.';
  static const errorEmptyImportList = 'Empty import list.';
  static const errorExtendsSelf = 'Class try to extends itself.';
  static const errorMissingFuncBody = 'Missing function definition of [{0}].';
  static const errorExternalCtorWithReferCtor =
      'Unexpected refer constructor on external constructor.';
  static const errorNonCotrWithReferCtor =
      'Unexpected refer constructor on normal function.';
  static const errorSourceProviderError =
      'Context error: could not load file: [{0}].';
  static const errorNotAbsoluteError =
      'Adding source failed, not a absolute path: [{0}].';
  static const errorInvalidLeftValue = 'Illegal left value.';
  static const errorNullableAssign = 'Cannot assign to a nullable value.';
  static const errorPrivateMember = 'Could not acess private member [{0}].';
  static const errorConstMustBeStatic =
      'Constant class member [{0}] must also be declared as static.';
  static const errorConstMustInit =
      'Constant declaration [{0}] must be initialized.';
  static const errorDuplicateLibStmt = 'Duplicate library statement.';
  static const errorNotConstValue = 'Constant declared with a non-const value.';

  // compile time errors
  static const errorDefined = '[{0}] is already defined.';
  static const errorOutsideThis =
      'Unexpected this expression outside of a function.';
  static const errorNotMember = '[{0}] is not a class member of [{1}].';
  static const errorNotClass = '[{0}] is not a class.';
  static const errorAbstracted = 'Cannot create instance from abstract class.';
  static const errorInterfaceCtor = 'Cannot create contructor for interfaces.';

  // runtime errors
  static const errorUnsupported = 'Unsupported operation: [{0}].';
  static const errorUnknownOpCode = 'Unknown opcode [{0}].';
  static const errorNotInitialized = '[{0}] has not yet been initialized.';
  static const errorUndefined = 'Undefined identifier [{0}].';
  static const errorUndefinedExternal = 'Undefined external identifier [{0}].';
  static const errorUnknownTypeName = 'Unknown type name: [{0}].';
  static const errorUndefinedOperator = 'Undefined operator: [{0}].';
  static const errorNotCallable = '[{0}] is not callable.';
  static const errorUndefinedMember = '[{0}] isn\'t defined for the class.';
  static const errorUninitialized = 'Varialbe [{0}] is not initialized yet.';
  static const errorCondition =
      'Condition expression must evaluate to type [bool]';
  static const errorNullObject = 'Calling method [{1}] on null object [{0}].';
  static const errorNullSubSetKey = 'Sub set key is null.';
  static const errorSubGetKey = 'Sub get key [{0}] is not of type [int]';
  static const errorOutOfRange = 'Index [{0}] is out of range [{1}].';
  static const errorAssignType =
      'Variable [{0}] with type [{2}] can\'t be assigned with type [{1}].';
  static const errorImmutable = '[{0}] is immutable.';
  static const errorNotType = '[{0}] is not a type.';
  static const errorArgType =
      'Argument [{0}] of type [{1}] doesn\'t match parameter type [{2}].';
  static const errorArgInit =
      'Only optional or named arguments can have initializer.';
  static const errorReturnType =
      '[{0}] can\'t be returned from function [{1}] with return type [{2}].';
  static const errorStringInterpolation =
      'String interpolation has to be a single expression.';
  static const errorArity =
      'Number of arguments [{0}] doesn\'t match function [{1}]\'s parameter requirement [{2}].';
  static const errorExternalVar = 'External variable is not allowed.';
  static const errorBytesSig = 'Unknown bytecode signature.';
  static const errorCircleInit =
      'Variable [{0}]\'s initializer depend on itself being initialized.';
  static const errorNamedArg = 'Undefined named parameter: [{0}].';
  static const errorIterable = '[{0}] is not Iterable.';
  static const errorUnkownValueType = 'Unkown OpCode value type: [{0}].';
  static const errorTypeCast = 'Type [{0}] cannot be cast into type [{1}].';
  static const errorCastee = 'Illegal cast target [{0}].';
  static const errorNotSuper = '[{0}] is not a super class of [{1}].';
  static const errorStructMemberId =
      'Struct member id should be symbol or string.';
  static const errorUnresolvedNamedStruct =
      'Cannot create struct object from unresolved prototype [{0}].';
  static const errorBinding =
      'Binding is not allowed on non-literal function or non-struct object.';
}
