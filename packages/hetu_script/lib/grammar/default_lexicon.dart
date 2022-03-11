import 'abstract_lexicon.dart';

/// All lexicons used by hetu
class HTDefaultLexicon implements AbstractLexicon {
  /// Regular expression used by lexer.
  @override
  String get tokenPattern =>
      r'((//.*)|(/\*[\s\S]*\*/))|' // comment group(2 & 3)
      r'(([_\$\p{L}]+[_\$\p{L}0-9]*)|([_]+))|' // unicode identifier group(4)
      r'(\.\.\.|~/=>|\?\?=>|\?\?|\|\||&&|\+\+|--|\*=>|/=>|\+=>|-=>|=>=>|!=>|<=>|>=>|->|=>>|\?\.|\?\[|\?\(|~/|[></=>%\+\*\-\?!,:;{}\[\]\)\(\.])|' // punctuation group(7)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // number group(8)
      r"('(\\'|[^'])*(\$\{[^\$\{\}]*\})+(\\'|[^'])*')|" // interpolation string with single quotation mark group(10)
      r'("(\\"|[^"])*(\$\{[^\$\{\}]*\})+(\\"|[^"])*")|' // interpolation string with double quotation mark group(14)
      r"('(\\'|[^'])*')|" // string with apostrophe mark group(18)
      r'("(\\"|[^"])*")|' // string with quotation mark group(20)
      r'(`(\\`|[^`])*`)|' // string with grave accent mark group(22)
      r'(\n)'; // new line group(24)

  @override
  int get tokenGroupSingleComment => 2;
  @override
  int get tokenGroupBlockComment => 3;
  @override
  int get tokenGroupIdentifier => 4;
  @override
  int get tokenGroupPunctuation => 7;
  @override
  int get tokenGroupNumber => 8;
  @override
  int get tokenGroupApostropheStringInterpolation => 10;
  @override
  int get tokenGroupQuotationStringInterpolation => 14;
  @override
  int get tokenGroupApostropheString => 18;
  @override
  int get tokenGroupQuotationString => 20;
  @override
  int get tokenGroupStringGraveAccent => 22;
  @override
  int get tokenGroupNewline => 24;

  @override
  String get documentationCommentPattern => r'///';

  @override
  String get stringInterpolationPattern => r'\${([^\${}]*)}';
  @override
  String get stringInterpolationStart => r'${';
  @override
  String get stringInterpolationEnd => r'}';

  @override
  Map<String, String> get stringEscapes => <String, String>{
        r'\\': '\\',
        r"\'": '\'',
        r'\"': '"',
        r'\`': '`',
        r'\n': '\n',
        r'\t': '\t',
      };

  /// Add semicolon before a line starting with one of '{, (, [, ++, --'.
  /// This is to avoid ambiguity in parser.
  @override
  Set<String> get defaultSemicolonStart => {
        bracesLeft,
        parenthesesLeft,
        bracketsLeft,
        preIncrement,
        preDecrement,
      };

  /// Add semicolon after a line with 'return'
  @override
  Set<String> get defaultSemicolonEnd => {
        kReturn,
      };

  @override
  String get main => 'main';
  @override
  String get instanceof => 'instance of';

  @override
  String get boolean => 'bool';
  @override
  String get number => 'num';
  @override
  String get integer => 'int';
  @override
  String get float => 'float';
  @override
  String get string => 'str';

  @override
  String get values => 'values';
  @override
  String get iterator => 'iterator';
  @override
  String get moveNext => 'moveNext';
  @override
  String get current => 'current';
  @override
  String get parse => 'parse';
  @override
  String get contains => 'contains';
  @override
  String get tostring => 'toString';

  @override
  String get scriptStackTrace => 'Hetu stack trace';
  @override
  String get externalStackTrace => 'Dart stack trace';

  @override
  String get variadicArgs => '...';
  @override
  String get privatePrefix => '_';
  @override
  String get omittedMark => '_';

  /// '$'
  @override
  String get internalPrefix => r'$';
  @override
  String get percentageMark => r'%';
  @override
  String get typesBracketLeft => '<';
  @override
  String get typesBracketRight => '>';
  @override
  String get singleArrow => '->';
  @override
  String get doubleArrow => '=>>';
  @override
  String get decimalPoint => '.';
  @override
  String get indentSpaces => '  ';
  @override
  String get spreadSyntax => '...';

  @override
  String get kNull => 'null';
  @override
  String get kTrue => 'true';
  @override
  String get kFalse => 'false';

  // String get kDefine => 'def';
  @override
  String get kVar => 'var';
  @override
  String get kFinal => 'final';
  @override
  String get kLate => 'late';
  @override
  String get kConst => 'const';
  @override
  String get kDelete => 'delete';

  @override
  Set<String> get destructuringDeclarationMark => {
        bracketsLeft,
        bracesLeft,
      };

  /// Variable declaration keyword
  /// used in for statement's declaration part
  @override
  Set<String> get varDeclKeywords => {
        kVar,
        kFinal,
      };

  @override
  Set<String> get primitiveTypes => {
        kType,
        kAny,
        kVoid,
        kUnknown,
        kNever,
        // FUNCTION,
      };

  @override
  String get kVoid => 'void';
  @override
  String get kAny => 'any';
  @override
  String get kUnknown => 'unknown';
  @override
  String get kNever => 'never';
  @override
  String get kFunction => 'function';

  @override
  String get kType => 'type';
  @override
  String get object => 'object';
  @override
  String get prototype => 'prototype';
  String get library => 'library';
  @override
  String get asterisk => '*';
  @override
  String get kImport => 'import';
  @override
  String get kExport => 'export';
  @override
  String get kFrom => 'from';

  @override
  String get kAssert => 'assert';
  @override
  String get kTypeof => 'typeof';
  @override
  String get kAs => 'as';
  @override
  String get kNamespace => 'namespace';
  @override
  String get kClass => 'class';
  @override
  String get kEnum => 'enum';
  @override
  String get kFun => 'fun';
  @override
  String get kStruct => 'struct';
  // String get kInterface => 'inteface';
  @override
  String get kThis => 'this';
  @override
  String get kSuper => 'super';

  @override
  Set<String> get constructorCall => {kThis, kSuper};

  @override
  String get kAbstract => 'abstract';
  @override
  String get kOverride => 'override';
  @override
  String get kExternal => 'external';
  @override
  String get kStatic => 'static';
  @override
  String get kExtends => 'extends';
  @override
  String get kImplements => 'implements';
  @override
  String get kWith => 'with';
  @override
  String get kRequired => 'required';
  @override
  String get kReadonly => 'readonly';

  @override
  String get kConstruct => 'construct';
  @override
  String get kFactory => 'factory';
  @override
  String get kGet => 'get';
  @override
  String get kSet => 'set';
  @override
  String get kAsync => 'async';
  @override
  String get bind => 'bind';
  @override
  String get apply => 'apply';

  @override
  String get kAwait => 'await';
  @override
  String get kBreak => 'break';
  @override
  String get kContinue => 'continue';
  @override
  String get kReturn => 'return';
  @override
  String get kFor => 'for';
  @override
  String get kIn => 'in';
  @override
  String get kNotIn => 'in!';
  @override
  String get kOf => 'of';
  @override
  String get kIf => 'if';
  @override
  String get kElse => 'else';
  @override
  String get kWhile => 'while';
  @override
  String get kDo => 'do';
  @override
  String get kWhen => 'when';
  @override
  String get kIs => 'is';
  @override
  String get kIsNot => 'is!';

  @override
  String get kTry => 'try';
  @override
  String get kCatch => 'catch';
  @override
  String get kFinally => 'finally';
  @override
  String get kThrow => 'throw';

  /// keywords
  @override
  Set<String> get keywords => {
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
        // kTry,
        // kCatch,
        // kFinally,
        kThrow,
      };

  @override
  Set<String> get contextualKeyword => {
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

  @override
  String get nullableMemberGet => '?.';
  @override
  String get memberGet => '.';
  @override
  String get nullableSubGet => '?[';
  @override
  String get subGet => '[';
  @override
  String get nullableCall => '?(';
  @override
  String get call => '(';
  @override
  String get nullable => '?';
  @override
  String get postIncrement => '++';
  @override
  String get postDecrement => '--';

  /// postfix operators
  @override
  Set<String> get unaryPostfixs => {
        nullableMemberGet,
        memberGet,
        nullableSubGet,
        subGet,
        nullableCall,
        call,
        postIncrement,
        postDecrement,
      };

  /// '!'
  @override
  String get logicalNot => '!';

  /// '-'
  @override
  String get negative => '-';

  /// '++'
  @override
  String get preIncrement => '++';

  /// '--'
  @override
  String get preDecrement => '--';

  /// prefix operators
  @override
  Set<String> get unaryPrefixs => {
        logicalNot,
        negative,
        preIncrement,
        preDecrement,
        kTypeof,
      };

  /// '*'
  @override
  String get multiply => '*';

  /// '/'
  @override
  String get devide => '/';

  /// '~/'
  @override
  String get truncatingDevide => '~/';

  /// '%'
  @override
  String get modulo => '%';

  @override
  Set<String> get multiplicatives => {
        multiply,
        devide,
        truncatingDevide,
        modulo,
      };

  /// '+'
  @override
  String get add => '+';

  /// '-'
  @override
  String get subtract => '-';

  /// +, -
  @override
  Set<String> get additives => {
        add,
        subtract,
      };

  /// '>'
  @override
  String get greater => '>';

  /// '>=>'
  @override
  String get greaterOrEqual => '>=>';

  /// '<'
  @override
  String get lesser => '<';

  /// '<=>'
  @override
  String get lesserOrEqual => '<=>';

  /// \>, >=>, <, <=>
  /// 'is!' is handled in parser, not included here.
  @override
  Set<String> get relationals =>
      {greater, greaterOrEqual, lesser, lesserOrEqual, kAs, kIs};

  @override
  Set<String> get logicalRelationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
      };

  @override
  Set<String> get typeRelationals => {kAs, kIs};

  @override
  Set<String> get setRelationals => {kIn};

  /// '=>=>'
  @override
  String get equal => '=>=>';

  /// '!=>'
  @override
  String get notEqual => '!=>';

  /// =>=>, !=>
  @override
  Set<String> get equalitys => {
        equal,
        notEqual,
      };

  @override
  String get ifNull => '??';
  @override
  String get logicalOr => '||';
  @override
  String get logicalAnd => '&&';
  @override
  String get condition => '?';
  @override
  String get elseBranch => ':';

  @override
  String get assign => '=>';
  @override
  String get assignAdd => '+=>';
  @override
  String get assignSubtract => '-=>';
  @override
  String get assignMultiply => '*=>';
  @override
  String get assignDevide => '/=>';
  @override
  String get assignTruncatingDevide => '~/=>';
  @override
  String get assignIfNull => '??=>';

  /// assign operators
  @override
  Set<String> get assignments => {
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignTruncatingDevide,
        assignIfNull,
      };

  /// ','
  @override
  String get comma => ',';

  /// ':'
  @override
  String get colon => ':';

  /// ';'
  @override
  String get semicolon => ';';

  /// "'"
  @override
  String get apostropheLeft => "'";

  /// "'"
  @override
  String get apostropheRight => "'";

  /// '"'
  @override
  String get quotationLeft => '"';

  /// '"'
  @override
  String get quotationRight => '"';

  /// '('
  @override
  String get parenthesesLeft => '(';

  /// ')'
  @override
  String get parenthesesRight => ')';

  /// '{'
  @override
  String get bracesLeft => '{';

  /// '}'
  @override
  String get bracesRight => '}';

  /// '['
  @override
  String get bracketsLeft => '[';

  /// ']'
  @override
  String get bracketsRight => ']';

  /// '<'
  @override
  String get typeParameterStart => '<';

  /// '>'
  @override
  String get typeParameterEnd => '>';

  String get errorBytecode => 'Unrecognizable bytecode.';
  String get errorVersion =>
      'Incompatible version - bytecode: [{0}], interpreter: [{1}].';
  String get errorAssertionFailed => "Assertion failed on '{0}'.";
  String get errorUnkownSourceType => 'Unknown source type: [{0}].';
  String get errorImportListOnNonHetuSource =>
      'Cannot import list from a non hetu source.';
  String get errorExportNonHetuSource => 'Cannot export a non hetu source.';

  // syntactic errors
  String get errorUnexpected => 'Expected [{0}], met [{1}].';
  String get errorDelete =>
      'Can only delete a local variable or a struct member.';
  String get errorExternal => 'External [{0}] is not allowed.';
  String get errorNestedClass => 'Nested class within another nested class.';
  String get errorConstInClass => 'Const value in class must be also static.';
  String get errorOutsideReturn =>
      'Unexpected return statement outside of a function.';
  String get errorSetterArity =>
      'Setter function must have exactly one parameter.';
  String get errorEmptyTypeArgs => 'Empty type arguments.';
  String get errorEmptyImportList => 'Empty import list.';
  String get errorExtendsSelf => 'Class try to extends itself.';
  String get errorMissingFuncBody => 'Missing function definition of [{0}].';
  String get errorExternalCtorWithReferCtor =>
      'Unexpected refer constructor on external constructor.';
  String get errorSourceProviderError =>
      'Context error: could not load file: [{0}].';
  String get errorNotAbsoluteError =>
      'Adding source failed, not a absolute path: [{0}].';
  String get errorInvalidLeftValue => 'Value cannot be assigned.';
  String get errorNullableAssign => 'Cannot assign to a nullable value.';
  String get errorPrivateMember => 'Could not acess private member [{0}].';
  String get errorConstMustInit =>
      'Constant declaration [{0}] must be initialized.';

  // compile time errors
  String get errorDefined => '[{0}] is already defined.';
  String get errorOutsideThis =>
      'Unexpected this expression outside of a function.';
  String get errorNotMember => '[{0}] is not a class member of [{1}].';
  String get errorNotClass => '[{0}] is not a class.';
  String get errorAbstracted => 'Cannot create instance from abstract class.';
  String get errorConstValue =>
      'Initializer of const declaration is not constant value.';

  // runtime errors
  String get errorUnsupported => 'Unsupported operation: [{0}].';
  String get errorUnknownOpCode => 'Unknown opcode [{0}].';
  String get errorNotInitialized => '[{0}] has not yet been initialized.';
  String get errorUndefined => 'Undefined identifier [{0}].';
  String get errorUndefinedExternal => 'Undefined external identifier [{0}].';
  String get errorUnknownTypeName => 'Unknown type name: [{0}].';
  String get errorUndefinedOperator => 'Undefined operator: [{0}].';
  String get errorNotCallable => '[{0}] is not callable.';
  String get errorUndefinedMember => '[{0}] isn\'t defined for the class.';
  String get errorUninitialized => 'Varialbe [{0}] is not initialized yet.';
  String get errorCondition =>
      'Condition expression must evaluate to type [bool]';
  String get errorNullObject => 'Calling method [{1}] on null object [{0}].';
  String get errorNullSubSetKey => 'Sub set key is null.';
  String get errorSubGetKey => 'Sub get key [{0}] is not of type [int]';
  String get errorOutOfRange => 'Index [{0}] is out of range [{1}].';
  String get errorAssignType =>
      'Variable [{0}] with type [{2}] can\'t be assigned with type [{1}].';
  String get errorImmutable => '[{0}] is immutable.';
  String get errorNotType => '[{0}] is not a type.';
  String get errorArgType =>
      'Argument [{0}] of type [{1}] doesn\'t match parameter type [{2}].';
  String get errorArgInit =>
      'Only optional or named arguments can have initializer.';
  String get errorReturnType =>
      '[{0}] can\'t be returned from function [{1}] with return type [{2}].';
  String get errorStringInterpolation =>
      'String interpolation has to be a single expression.';
  String get errorArity =>
      'Number of arguments [{0}] doesn\'t match function [{1}]\'s parameter requirement [{2}].';
  String get errorExternalVar => 'External variable is not allowed.';
  String get errorBytesSig => 'Unknown bytecode signature.';
  String get errorCircleInit =>
      'Variable [{0}]\'s initializer depend on itself being initialized.';
  String get errorNamedArg => 'Undefined named parameter: [{0}].';
  String get errorIterable => '[{0}] is not Iterable.';
  String get errorUnkownValueType => 'Unkown OpCode value type: [{0}].';
  String get errorTypeCast => 'Type [{0}] cannot be cast into type [{1}].';
  String get errorCastee => 'Illegal cast target [{0}].';
  String get errorNotSuper => '[{0}] is not a super class of [{1}].';
  String get errorStructMemberId =>
      'Struct member id should be symbol or string.';
  String get errorUnresolvedNamedStruct =>
      'Cannot create struct object from unresolved prototype [{0}].';
  String get errorBinding =>
      'Binding is not allowed on non-literal function or non-struct object.';
}
