/// Lexicon used by Hetu,
class HTLexicon {
  /// Regular expression used by lexer.
  static const tokenPattern =
      r'((//.*)|(/\*[\s\S]*\*/))|' // comment group(2 & 3)
      r'(\.\.\.|~/=|\?\?=|\?\?|\|\||&&|\+\+|--|\*=|/=|\+=|-=|==|!=|<=|>=|->|=>|\?\.|\?\[|\?\(|~/|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // punctuation group(4)
      r'(([_\$\p{L}]+[_\$\p{L}0-9]*)|([_]+))|' // unicode identifier group(5)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // number group(8)
      r"('(\\'|[^'])*(\$\{[^\$\{\}]*\})+(\\'|[^'])*')|" // interpolation string with single quotation mark group(10)
      r'("(\\"|[^"])*(\$\{[^\$\{\}]*\})+(\\"|[^"])*")|' // interpolation string with double quotation mark group(14)
      r"('(\\'|[^'])*')|" // string with apostrophe mark group(18)
      r'("(\\"|[^"])*")|' // string with quotation mark group(20)
      r'(`(\\`|[^`])*`)|' // string with grave accent mark group(22)
      r'(\n)'; // new line group(24)

  static const tokenGroupSingleComment = 2;
  static const tokenGroupBlockComment = 3;
  static const tokenGroupPunctuation = 4;
  static const tokenGroupIdentifier = 5;
  static const tokenGroupNumber = 8;
  static const tokenGroupApostropheStringInterpolation = 10;
  static const tokenGroupQuotationStringInterpolation = 14;
  static const tokenGroupApostropheString = 18;
  static const tokenGroupQuotationString = 20;
  static const tokenGroupStringGraveAccent = 22;
  static const tokenGroupNewline = 24;

  static const documentationCommentPattern = r'///';

  static const stringInterpolationPattern = r'\${([^\${}]*)}';
  static const stringInterpolationMark = r'$';
  static const stringInterpolationStart = r'{';
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

  static const List<String> unfinishedTokens = [
    logicalNot,
    multiply,
    devide,
    modulo,
    add,
    subtract,
    lesser,
    lesserOrEqual,
    greater,
    greaterOrEqual,
    equal,
    notEqual,
    ifNull,
    logicalAnd,
    logicalOr,
    assign,
    assignAdd,
    assignSubtract,
    assignMultiply,
    assignDevide,
    assignIfNull,
    memberGet,
    groupExprStart,
    functionBlockStart,
    subGetStart,
    listStart,
    optionalPositionalParameterStart,
    externalFunctionTypeDefStart,
    comma,
    constructorInitializationListIndicator,
    namedArgumentValueIndicator,
    typeIndicator,
    structValueIndicator,
    functionReturnTypeIndicator,
    whenBranchIndicator,
    functionSingleLineBodyIndicator,
    typeParameterStart,
  ];

  static const globalObjectId = 'object';
  static const globalPrototypeId = 'prototype';
  static const programEntryFunctionId = 'main';

  static const typeVoid = 'void';
  static const typeAny = 'any';
  static const typeUnknown = 'unknown';
  static const typeNever = 'never';
  static const typeFunction = 'function';
  static const typeBoolean = 'bool';
  static const typeNumber = 'int';
  static const typeFloat = 'float';
  static const typeString = 'str';

  static const propertyCollectionValues = 'values';
  static const propertyCollectionContains = 'contains';
  static const propertyIterableIterator = 'iterator';
  static const propertyIterableIteratorMoveNext = 'moveNext';
  static const propertyIterableIteratorCurrent = 'current';
  static const propertyToString = 'toString';

  /// ...
  static const variadicArgs = '...';

  /// _
  static const privatePrefix = '_';

  /// _
  static const omittedMark = '_';

  /// $
  static const internalPrefix = r'$';

  /// ->
  static const functionReturnTypeIndicator = '->';

  /// ->
  static const whenBranchIndicator = '->';

  /// =>
  static const functionSingleLineBodyIndicator = '=>';

  /// .
  static const decimalPoint = '.';

  /// ...
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
    structStart,
  };

  /// Variable declaration keyword
  /// used in for statement's declaration part
  static const Set<String> forDeclarationKeywords = {
    kVar,
    kFinal,
  };

  static const kType = 'type';

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
  static const kNew = 'new';
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
    kWith,
    kNew,
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

  /// ?.
  static const nullableMemberGet = '?.';

  /// .
  static const memberGet = '.';

  /// ?[
  static const nullableSubGet = '?[';

  /// ?(
  static const nullableFunctionCallArgumentStart = '?(';

  /// (
  static const functionCallArgumentStart = '(';

  /// )
  static const functionCallArgumentEnd = ')';

  /// ?
  static const nullableTypePostfix = '?';

  /// ++
  static const postIncrement = '++';

  /// --
  static const postDecrement = '--';

  /// postfix operators
  static const Set<String> unaryPostfixs = {
    nullableMemberGet,
    memberGet,
    nullableSubGet,
    subGetStart,
    nullableFunctionCallArgumentStart,
    functionCallArgumentStart,
    postIncrement,
    postDecrement,
  };

  /// prefix operators that modify the value
  static const Set<String> unaryPrefixsOnLeftValue = {
    preIncrement,
    preDecrement,
  };

  /// !
  static const logicalNot = '!';

  /// -
  static const negative = '-';

  /// ++
  static const preIncrement = '++';

  /// --
  static const preDecrement = '--';

  /// prefix operators
  static const Set<String> unaryPrefixs = {
    logicalNot,
    negative,
    preIncrement,
    preDecrement,
    kTypeof,
  };

  /// *
  static const multiply = '*';

  /// /
  static const devide = '/';

  /// ~/
  static const truncatingDevide = '~/';

  /// %'
  static const modulo = '%';

  static const Set<String> multiplicatives = {
    multiply,
    devide,
    truncatingDevide,
    modulo,
  };

  /// +
  static const add = '+';

  /// -
  static const subtract = '-';

  /// +, -
  static const Set<String> additives = {
    add,
    subtract,
  };

  /// >
  static const greater = '>';

  /// >=
  static const greaterOrEqual = '>=';

  /// <
  static const lesser = '<';

  /// <=
  static const lesserOrEqual = '<=';

  /// \>, >=, <, <=
  static const Set<String> logicalRelationals = {
    greater,
    greaterOrEqual,
    lesser,
    lesserOrEqual,
  };

  static const Set<String> typeRelationals = {kAs, kIs};

  static const Set<String> setRelationals = {kIn};

  /// ==
  static const equal = '==';

  /// !=
  static const notEqual = '!=';

  /// ==, !=
  static const Set<String> equalitys = {
    equal,
    notEqual,
  };

  /// ??
  static const ifNull = '??';

  /// ||
  static const logicalOr = '||';

  /// &&
  static const logicalAnd = '&&';

  /// ?
  static const ternaryThen = '?';

  /// :
  static const ternaryElse = ':';

  /// :
  static const assign = '=';

  /// +=
  static const assignAdd = '+=';

  /// -=
  static const assignSubtract = '-=';

  /// *=
  static const assignMultiply = '*=';

  /// /=
  static const assignDevide = '/=';

  /// ~/=
  static const assignTruncatingDevide = '~/=';

  /// ??=
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

  /// ,
  static const comma = ',';

  /// :
  static const constructorInitializationListIndicator = ':';

  /// :
  static const namedArgumentValueIndicator = ':';

  /// :
  static const typeIndicator = ':';

  /// :
  static const structValueIndicator = ':';

  /// ;
  static const endOfStatementMark = ';';

  /// '
  static const apostropheStringLeft = "'";

  /// '
  static const apostropheStringRight = "'";

  /// "
  static const quotationStringLeft = '"';

  /// "
  static const quotationStringRight = '"';

  /// (
  static const groupExprStart = '(';

  /// )
  static const groupExprEnd = ')';

  /// {
  static const functionBlockStart = '{';

  /// }
  static const functionBlockEnd = '}';

  /// {
  static const declarationBlockStart = '{';

  /// }
  static const declarationBlockEnd = '}';

  /// {
  static const structStart = '{';

  /// }
  static const structEnd = '}';

  /// [
  static const subGetStart = '[';

  /// ]
  static const subGetEnd = ']';

  /// [
  static const listStart = '[';

  /// ]
  static const listEnd = ']';

  /// [
  static const optionalPositionalParameterStart = '[';

  /// ]
  static const optionalPositionalParameterEnd = ']';

  /// {
  static const namedParameterStart = '{';

  /// }
  static const namedParameterEnd = '}';

  /// [
  static const externalFunctionTypeDefStart = '[';

  /// ]
  static const externalFunctionTypeDefEnd = ']';

  /// <
  static const typeParameterStart = '<';

  /// >
  static const typeParameterEnd = '>';
}
