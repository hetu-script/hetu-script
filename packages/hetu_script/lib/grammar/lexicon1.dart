/// All lexicons used by hetu
abstract class AbstractLexicon {
  /// Regular expression used by lexer.
  String get tokenPattern;

  String get tokenGroupSingleComment;
  String get tokenGroupBlockComment;
  String get tokenGroupIdentifier;
  String get tokenGroupPunctuation;
  String get tokenGroupNumber;
  String get tokenGroupApostropheStringInterpolation;
  String get tokenGroupQuotationStringInterpolation;
  String get tokenGroupApostropheString;
  String get tokenGroupQuotationString;
  String get tokenGroupStringGraveAccent;
  String get tokenGroupNewline;

  String get singleLineCommentDocumentationPattern;
  String get multiLineCommentDocumentationPattern;

  String get libraryNamePattern;

  String get libraryNameSingleMark;
  String get libraryNameDoubleMark;

  String get stringInterpolationPattern;
  String get stringInterpolationStart;
  String get stringInterpolationEnd;

  Map<String, String> get stringEscapes;

  /// Add semicolon before a line starting with one of '{, (, [, ++, --'.
  /// This is to avoid ambiguity in parser.
  Set<String> get defaultSemicolonStart;

  /// Add semicolon after a line with 'return'
  Set<String> get defaultSemicolonEnd;

  String get main;
  String get instanceof;

  String get boolean;
  String get number;
  String get integer;
  String get float;
  String get string;

  String get values;
  String get iterator;
  String get moveNext;
  String get current;
  String get parse;
  String get contains;
  String get tostring;

  String get scriptStackTrace;
  String get externalStackTrace;

  String get variadicArgs;
  String get privatePrefix;
  String get omittedMark;

  /// '$'
  String get internalPrefix;
  String get percentageMark;
  String get typesBracketLeft;
  String get typesBracketRight;
  String get singleArrow;
  String get doubleArrow;
  String get decimalPoint;
  String get indentSpaces;
  String get spreadSyntax;

  String get kNull;
  String get kTrue;
  String get kFalse;

  // String get kDefine = 'def';
  String get kVar;
  String get kFinal;
  String get kLate;
  String get kConst;
  String get kDelete;

  Set<String> get destructuringDeclarationMark;

  /// 变量声明
  Set<String> get varDeclKeywords;

  Set<String> get primitiveTypes;

  String get kVoid;
  String get kAny;
  String get kUnknown;
  String get kNever;
  String get kFunction;

  String get kType;
  String get object;
  String get prototype;
  String get asterisk;
  String get kImport;
  String get kExport;
  String get kFrom;

  String get kAssert;
  String get kTypeof;
  String get kAs;
  String get kNamespace;
  String get kClass;
  String get kEnum;
  String get kFun;
  String get kStruct;
  // String get kInterface = 'inteface';
  String get kThis;
  String get kSuper;

  Set<String> get constructorCall;

  String get kAbstract;
  String get kOverride;
  String get kExternal;
  String get kStatic;
  String get kExtends;
  String get kImplements;
  String get kWith;
  String get kRequired;
  String get kReadonly;

  String get kConstruct;
  String get kFactory;
  String get kGet;
  String get kSet;
  String get kAsync;
  String get bind;
  String get apply;

  String get kAwait;
  String get kBreak;
  String get kContinue;
  String get kReturn;
  String get kFor;
  String get kIn;
  String get kNotIn;
  String get kOf;
  String get kIf;
  String get kElse;
  String get kWhile;
  String get kDo;
  String get kWhen;
  String get kIs;
  String get kIsNot;

  String get kTry;
  String get kCatch;
  String get kFinally;
  String get kThrow;

  Set<String> get keywords;

  Set<String> get contextualKeyword;

  String get nullableMemberGet;
  String get memberGet;
  String get nullableSubGet;
  String get subGet;
  String get nullableCall;
  String get call;
  String get nullable;
  String get postIncrement;
  String get postDecrement;

  /// postfix operators
  Set<String> get unaryPostfixs;

  /// '!'
  String get logicalNot;

  /// '-'
  String get negative;

  /// '++'
  String get preIncrement;

  /// '--'
  String get preDecrement;

  /// prefix operators
  Set<String> get unaryPrefixs;

  /// '*'
  String get multiply;

  /// '/'
  String get devide;

  /// '~/'
  String get truncatingDevide;

  /// '%'
  String get modulo;

  /// multiplicatives operators
  Set<String> get multiplicatives;

  /// '+'
  String get add;

  /// '-'
  String get subtract;

  /// +, -
  Set<String> get additives;

  /// '>'
  String get greater;

  /// '>='
  String get greaterOrEqual;

  /// '<'
  String get lesser;

  /// '<='
  String get lesserOrEqual;

  /// \>, >=, <, <=
  /// 'is!' is handled in parser, not included here.
  Set<String> get relationals;

  Set<String> get logicalRelationals;

  Set<String> get typeRelationals;

  Set<String> get setRelationals;

  /// '=='
  String get equal;

  /// '!='
  String get notEqual;

  /// ==, !=
  Set<String> get equalitys;

  String get ifNull;
  String get logicalOr;
  String get logicalAnd;
  String get condition;
  String get elseBranch;

  String get assign;
  String get assignAdd;
  String get assignSubtract;
  String get assignMultiply;
  String get assignDevide;
  String get assignTruncatingDevide;
  String get assignIfNull;

  /// assign operators
  Set<String> get assignments;

  /// ','
  String get comma;

  /// ':'
  String get colon;

  /// ';'
  String get semicolon;

  /// "'"
  String get apostropheLeft;

  /// "'"
  String get apostropheRight;

  /// '"'
  String get quotationLeft;

  /// '"'
  String get quotationRight;

  /// '('
  String get parenthesesLeft;

  /// ')'
  String get parenthesesRight;

  /// '{'
  String get bracesLeft;

  /// '}'
  String get bracesRight;

  /// '['
  String get bracketsLeft;

  /// ']'
  String get bracketsRight;

  /// '<'
  String get chevronsLeft;

  /// '>'
  String get chevronsRight;
}
