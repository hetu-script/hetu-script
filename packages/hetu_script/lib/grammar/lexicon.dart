/// All lexicons used by hetu
class HTLexicon {
  /// Regular expression used by lexer.
  static const tokenPattern =
      r'((//.*)|(/\*[\s\S]*\*/))|' // comment group(2 & 3)
      r'(([_\$\p{L}]+[_\$\p{L}0-9]*)|([_]+))|' // unicode identifier group(4)
      r'(\.\.\.|~/=|\?\?=|\?\?|\|\||&&|\+\+|--|\*=|/=|\+=|-=|==|!=|<=|>=|->|=>|\?\.|\?\[|\?\(|~/|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // punctuation group(7)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // number group(8)
      r"('(\\'|[^'])*(\$\{[^\$\{\}]*\})+(\\'|[^'])*')|" // interpolation string with single quotation mark group(10)
      r'("(\\"|[^"])*(\$\{[^\$\{\}]*\})+(\\"|[^"])*")|' // interpolation string with double quotation mark group(14)
      r"('(\\'|[^'])*')|" // string with apostrophe mark group(18)
      r'("(\\"|[^"])*")|' // string with quotation mark group(20)
      r'(`(\\`|[^`])*`)|' // string with grave accent mark group(22)
      r'(\n)'; // new line group(24)

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
  static const tokenGroupNewline = 24;

  static const documentationCommentPattern = r'///';

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
  static const List<String> autoSemicolonInsertAtStart = [
    functionBlockStart,
    groupExprStart,
    listStart,
    preIncrement,
    preDecrement,
  ];

  /// Add semicolon after a line with 'return'
  static const Set<String> autoSemicolonInsertAtEnd = {
    kReturn,
  };

  static const main = 'main';
  static const instanceof = 'instance of';

  static const boolean = 'bool';
  static const integer = 'int';
  static const float = 'float';
  static const string = 'str';

  static const values = 'values';
  static const iterator = 'iterator';
  static const moveNext = 'moveNext';
  static const current = 'current';
  static const contains = 'contains';
  static const tostring = 'toString';

  static const scriptStackTrace = 'Hetu stack trace';
  static const externalStackTrace = 'Dart stack trace';

  /// '...'
  static const variadicArgs = '...';

  /// '_'
  static const privatePrefix = '_';

  /// '_'
  static const omittedMark = '_';

  /// '$'
  static const internalPrefix = r'$';

  /// '->'
  static const functionReturnTypeIndicator = '->';

  /// '->'
  static const whenBranchIndicator = '->';

  /// '=>'
  static const functionSingleLineBodyIndicator = '=>';

  /// '.'
  static const decimalPoint = '.';

  /// indent space
  static const indentSpaces = '  ';

  /// '...'
  static const spreadSyntax = '...';

  static const kNull = 'null';
  static const kTrue = 'true';
  static const kFalse = 'false';

  // static const kDefine = 'def';
  static const kVar = 'var';
  static const kFinal = 'final';
  static const kLate = 'late';
  static const kConst = 'const';
  static const kDelete = 'delete';

  static const Set<String> destructuringDeclarationMark = {
    listStart,
    functionBlockStart,
  };

  /// Variable declaration keyword
  /// used in for statement's declaration part
  static const Set<String> forDeclarationKeywords = {
    kVar,
    kFinal,
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
  // static const kInterface = 'inteface';
  static const kThis = 'this';
  static const kSuper = 'super';

  static const Set<String> redirectingConstructorCallKeywords = {kThis, kSuper};

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

  /// reserved keywords, cannot used as identifier names
  static const Set<String> keywords = {
    kNull,
    kTrue,
    kFalse,
    kVar,
    kFinal,
    kLate,
    kConst,
    kDelete,
    kAssert,
    kTypeof,
    kNamespace,
    kClass,
    kEnum,
    kFun,
    kStruct,
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
    kAsync,
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
    kThrow,
    // kTry,
    // kCatch,
    // kFinally,
  };

  /// '?.'
  static const nullableMemberGet = '?.';

  /// '.'
  static const memberGet = '.';

  /// '?['
  static const nullableSubGet = '?[';

  /// '?('
  static const nullableCall = '?(';

  /// '('
  static const call = '(';

  /// '?'
  static const nullable = '?';

  /// '++'
  static const postIncrement = '++';

  /// '--'
  static const postDecrement = '--';

  /// postfix operators
  static const Set<String> unaryPostfixs = {
    nullableMemberGet,
    memberGet,
    nullableSubGet,
    subGetStart,
    nullableCall,
    call,
    postIncrement,
    postDecrement,
  };

  /// '!'
  static const logicalNot = '!';

  /// '-'
  static const negative = '-';

  /// '++'
  static const preIncrement = '++';

  /// '--'
  static const preDecrement = '--';

  /// prefix operators
  static const Set<String> unaryPrefixs = {
    logicalNot,
    negative,
    preIncrement,
    preDecrement,
    kTypeof,
  };

  /// '*'
  static const multiply = '*';

  /// '/'
  static const devide = '/';

  /// '~/'
  static const truncatingDevide = '~/';

  /// '%'
  static const modulo = '%';

  static const Set<String> multiplicatives = {
    multiply,
    devide,
    truncatingDevide,
    modulo,
  };

  /// '+'
  static const add = '+';

  /// '-'
  static const subtract = '-';

  /// +, -
  static const Set<String> additives = {
    add,
    subtract,
  };

  /// '>'
  static const greater = '>';

  /// '>='
  static const greaterOrEqual = '>=';

  /// '<'
  static const lesser = '<';

  /// '<='
  static const lesserOrEqual = '<=';

  /// \>, >=, <, <=
  /// 'is!' is handled in parser, not included here.
  static const Set<String> relationals = {
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
    kAs,
    kIs
  };

  static const Set<String> logicalRelationals = {
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
  };

  static const Set<String> typeRelationals = {kAs, kIs};

  static const Set<String> setRelationals = {kIn};

  /// '=='
  static const equal = '==';

  /// '!='
  static const notEqual = '!=';

  /// ==, !=
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

  /// assign operators
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
  static const endOfStatementMark = ';';

  /// "'"
  static const apostropheStringLeft = "'";

  /// "'"
  static const apostropheStringRight = "'";

  /// '"'
  static const quotationStringLeft = '"';

  /// '"'
  static const quotationStringRight = '"';

  /// '('
  static const groupExprStart = '(';

  /// ')'
  static const groupExprEnd = ')';

  /// '{'
  static const functionBlockStart = '{';

  /// '}'
  static const functionBlockEnd = '}';

  /// '{'
  static const namespaceBlockStart = '{';

  /// '}'
  static const namespaceBlockEnd = '}';

  /// '['
  static const subGetStart = '[';

  /// ']'
  static const subGetEnd = ']';

  /// '['
  static const listStart = '[';

  /// ']'
  static const listEnd = ']';

  /// '['
  static const optionalPositionalParameterStart = '[';

  /// ']'
  static const optionalPositionalParameterEnd = ']';

  /// '['
  static const externalFunctionTypeDefStart = '[';

  /// ']'
  static const externalFunctionTypeDefEnd = ']';

  /// '<'
  static const typeParameterStart = '<';

  /// '>'
  static const typeParameterEnd = '>';
}
