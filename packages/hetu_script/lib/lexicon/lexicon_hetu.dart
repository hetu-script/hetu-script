import 'lexicon.dart';

/// Default lexicon implementation used by Hetu.
/// Most of the lexicon are borrowed from Javascript.
class HTLexiconHetu extends HTLexicon {
  @override
  String get name => r'lexicon_javascript';

  @override
  String get identifierStartPattern => r'[_#\$\p{L}]';

  @override
  String get identifierPattern => r'[_\$\p{L}0-9]';

  @override
  String get numberStartPattern => r'[\.\d]';

  @override
  String get numberPattern => r'[\.\d]';

  @override
  String get digitPattern => r'\d';

  @override
  String get hexNumberPattern => r'[0-9a-fA-F]';

  @override
  String get stringInterpolationPattern => r'\${([^\${}]*)}';

  @override
  String get hexNumberStart => r'0x';

  @override
  String get singleLineCommentStart => r'//';

  @override
  String get multiLineCommentStart => r'/*';

  @override
  String get multiLineCommentEnd => r'*/';

  @override
  String get documentationCommentStart => r'///';

  @override
  String get stringInterpolationStart => r'${';

  @override
  String get stringInterpolationEnd => r'}';

  @override
  String get escapeCharacterStart => r'\';

  @override
  Map<String, String> get escapeCharacters => <String, String>{
        r'\\': '\\',
        r"\'": "'",
        r'\"': '"',
        r'\`': '`',
        r'\n': '\n',
        r'\t': '\t',
      };

  @override
  String get globalObjectId => 'Object';

  @override
  String get globalPrototypeId => 'Prototype';

  @override
  Set<String> get privatePrefixes => {
        '#',
        '_',
      };

  @override
  String get preferredPrivatePrefix => '#';

  @override
  String get internalPrefix => r'__';

  @override
  String get kAny => 'any';

  @override
  String get kUnknown => 'unknown';

  @override
  String get kVoid => 'void';

  @override
  String get kNever => 'never';

  @override
  String get kType => 'type';

  @override
  String get kBoolean => 'bool';

  @override
  String get kNumber => 'num';

  @override
  String get kInteger => 'int';

  @override
  String get kFloat => 'float';

  @override
  String get kString => 'str';

  @override
  String get kNull => 'null';

  @override
  String get kTrue => 'true';

  @override
  String get kFalse => 'false';

  @override
  Set<String> get kMutables => {'let', 'var'};

  @override
  String get kImmutable => 'final';

  @override
  String get kLate => 'late';

  @override
  String get kConst => 'const';

  @override
  String get kDelete => 'delete';

  @override
  String get kTypeDef => 'type';

  @override
  String get kTypeOf => 'typeof';

  @override
  String get kDeclTypeof => 'decltypeof';

  @override
  String get kTypeValue => 'typeval';

  @override
  String get kImport => 'import';

  @override
  String get kExport => 'export';

  @override
  String get kFrom => 'from';

  @override
  String get kAssert => 'assert';

  @override
  String get kAs => 'as';

  @override
  String get kNamespace => 'namespace';

  @override
  String get kClass => 'class';

  @override
  String get kEnum => 'enum';

  @override
  Set<String> get kFunctions => {'function', 'fun'};

  @override
  String get kStruct => 'struct';

  @override
  String get kAlias => 'alias';

  @override
  String get kThis => 'this';

  @override
  String get kSuper => 'super';

  @override
  String get kAbstract => 'abstract';

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
  Set<String> get kConstructors => {'constructor', 'construct'};

  @override
  String get kNew => 'new';

  @override
  String get kFactory => 'factory';

  @override
  String get kGet => 'get';

  @override
  String get kSet => 'set';

  @override
  String get kAsync => 'async';

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
  Set<String> get kSwitchs => {'switch', 'when'};

  @override
  String get kCase => 'case';

  @override
  String get kDefault => 'default';

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

  @override
  String get indent => '  ';

  @override
  String get decimalPoint => '.';

  @override
  String get variadicArgs => '...';

  @override
  String get spreadSyntax => '...';

  @override
  String get omittedMark => '_';

  @override
  String get everythingMark => '*';

  @override
  String get defaultMark => '_';

  @override
  String get singleLineFunctionIndicator => '=>';

  @override
  String get literalFunctionIndicator => '=>';

  @override
  String get returnTypeIndicator => '->';

  @override
  String get switchBranchIndicator => '=>';

  @override
  String get nullableMemberGet => '?.';

  @override
  String get memberGet => '.';

  @override
  String get nullableSubGet => '?[';

  @override
  String get nullableFunctionArgumentCall => '?(';

  @override
  String get subGetStart => '[';

  @override
  String get subGetEnd => ']';

  @override
  String get functionParameterStart => '(';

  @override
  String get functionParameterEnd => ')';

  @override
  String get functionNamedParameterStart => '{';

  @override
  String get functionNamedParameterEnd => '}';

  @override
  String get functionPositionalParameterStart => '[';

  @override
  String get functionPositionalParameterEnd => ']';

  @override
  String get nullableTypePostfix => '?';

  @override
  String get postIncrement => '++';

  @override
  String get postDecrement => '--';

  @override
  String get logicalNot => '!';

  @override
  String get bitwiseNot => '~';

  @override
  String get negative => '-';

  @override
  String get preIncrement => '++';

  @override
  String get preDecrement => '--';

  @override
  String get multiply => '*';

  @override
  String get devide => '/';

  @override
  String get truncatingDevide => '~/';

  @override
  String get modulo => '%';

  @override
  String get add => '+';

  @override
  String get subtract => '-';

  @override
  String get leftShift => '<<';

  @override
  String get rightShift => '>>';

  @override
  String get unsignedRightShift => '>>>';

  @override
  String get bitwiseAnd => '&';

  @override
  String get bitwiseXor => '^';

  @override
  String get bitwiseOr => '|';

  @override
  String get greater => '>';

  @override
  String get greaterOrEqual => '>=';

  @override
  String get lesser => '<';

  @override
  String get lesserOrEqual => '<=';

  @override
  String get equal => '==';

  @override
  String get notEqual => '!=';

  @override
  String get strictEqual => '===';

  @override
  String get strictNotEqual => '!==';

  @override
  String get logicalAnd => '&&';

  @override
  String get logicalOr => '||';

  @override
  String get ifNull => '??';

  @override
  String get ternaryThen => '?';

  @override
  String get ternaryElse => ':';

  @override
  String get cascade => '..';

  @override
  String get nullableCascade => '?..';

  @override
  String get assign => '=';

  @override
  String get assignAdd => '+=';

  @override
  String get assignSubtract => '-=';

  @override
  String get assignMultiply => '*=';

  @override
  String get assignDevide => '/=';

  @override
  String get assignTruncatingDevide => '~/=';

  @override
  String get assignIfNull => '??=';

  @override
  String get assignBitwiseAnd => '&=';

  @override
  String get assignBitwiseOr => '|=';

  @override
  String get assignBitwiseXor => '^=';

  @override
  String get assignLeftShift => '<<=';

  @override
  String get assignRightShift => '>>=';

  @override
  String get assignUnsignedRightShift => '>>>=';

  @override
  String get comma => ',';

  @override
  String get constructorInitializationListIndicator => ':';

  @override
  String get namedArgumentValueIndicator => ':';

  @override
  String get typeIndicator => ':';

  @override
  String get structValueIndicator => ':';

  @override
  String get endOfStatementMark => ';';

  @override
  String get stringStart1 => "'";

  @override
  String get stringEnd1 => "'";

  @override
  String get stringStart2 => '"';

  @override
  String get stringEnd2 => '"';

  @override
  String get identifierStart => '`';

  @override
  String get identifierEnd => '`';

  @override
  String get groupExprStart => '(';

  @override
  String get groupExprEnd => ')';

  @override
  String get blockStart => '{';

  @override
  String get blockEnd => '}';

  @override
  String get enumStart => '{';

  @override
  String get enumEnd => '}';

  @override
  String get namespaceStart => '{';

  @override
  String get namespaceEnd => '}';

  @override
  String get classStart => '{';

  @override
  String get classEnd => '}';

  @override
  String get functionStart => '{';

  @override
  String get functionEnd => '}';

  @override
  String get structStart => '{';

  @override
  String get structEnd => '}';

  @override
  String get listStart => '[';

  @override
  String get listEnd => ']';

  @override
  String get externalFunctionTypeDefStart => '[';

  @override
  String get externalFunctionTypeDefEnd => ']';

  @override
  String get typeListStart => '<';

  @override
  String get typeListEnd => '>';

  @override
  String get importExportListStart => '{';

  @override
  String get importExportListEnd => '}';

  @override
  String get idEnumItemName => 'name';

  @override
  String get idCollectionValues => 'values';

  @override
  String get idCollectionContains => 'contains';

  @override
  String get idIterableIterator => 'iterator';

  @override
  String get idIterableIteratorMoveNext => 'moveNext';

  @override
  String get idIterableIteratorCurrent => 'current';

  @override
  String get idToString => 'toString';

  @override
  String get idBind => 'bind';

  @override
  String get idApply => 'apply';

  @override
  String get idThen => 'then';
}
