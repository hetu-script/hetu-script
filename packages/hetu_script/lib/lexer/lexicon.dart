/// Lexicon used by Hetu,
abstract class HTLexicon {
  /// the unique name of this lexicon.
  String get name;

  String get identifierStartPattern;
  String get identifierPattern;
  String get numberStartPattern;
  String get digitPattern;
  String get numberPattern;
  String get hexNumberPattern;
  String get stringInterpolationPattern;

  /// a character sequence that marked the start of literal hex number.
  String get hexNumberStart;

  /// a character sequence that marked the start of single line comment.
  String get singleLineCommentStart;

  /// a character sequence that marked the start of multiline line comment.
  String get multiLineCommentStart;

  /// a character sequence that marked the end of multiline line comment.
  String get multiLineCommentEnd;

  /// a character sequence that marked the start of documentation comment.
  String get documentationCommentStart;

  /// a character sequence that marked the start of interpolation in strings.
  String get stringInterpolationStart;

  /// a single character that marked the end of interpolation in strings.
  String get stringInterpolationEnd;

  /// a single character that marked the start of escape in strings.
  String get escapeCharacterStart;

  /// escaped characters mapping.
  Map<String, String> get escapeCharacters;

  /// Add semicolon before a line starting with one of '{, (, [, ++, --'.
  /// This is to avoid ambiguity in parser.
  List<String> get autoSemicolonInsertAtStart => [
        codeBlockStart,
        functionParameterStart,
        subGetStart,
        preIncrement,
        preDecrement,
      ];

  /// Add semicolon after a line with 'return'
  List<String> get autoSemicolonInsertAtEnd => [
        kReturn,
      ];

  List<String> get unfinishedTokens => [
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
        codeBlockStart,
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
        typeListStart,
      ];

  String get globalObjectId;
  String get globalPrototypeId;
  String get programEntryFunctionId;

  String get privatePrefix;
  String get internalPrefix;

  String get typeAny;
  String get typeUnknown;
  String get typeVoid;
  String get typeNever;
  String get typeFunction;
  String get typeNamespace;

  Set<String> get builtinIntrinsicTypes => {
        typeAny,
        typeUnknown,
        typeVoid,
        typeNever,
      };

  String get typeBoolean;
  String get typeNumber;
  String get typeInteger;
  String get typeFloat;
  String get typeString;

  Set<String> get builtinNominalTypes => {
        typeBoolean,
        typeNumber,
        typeInteger,
        typeFloat,
        typeString,
      };

  /// `values` api.
  String get idCollectionValues;

  /// `contains` api.
  String get idCollectionContains;

  /// `iterator` api on Iterable.
  String get idIterableIterator;

  /// `moveNext()` api on iterator.
  String get idIterableIteratorMoveNext;

  /// `current` api on iterator.
  String get idIterableIteratorCurrent;

  /// `toString()` api on Object & struct object.
  String get idToString;

  /// `bind()` api on function object.
  String get idBind;

  /// `apply()` api on function object.
  String get idApply;

  /// `then()` api on Future object.
  String get idThen;

  // Set<String> get primitiveTypes => {
  //       kType,
  //       kNull,
  //       typeAny,
  //       typeVoid,
  //       typeUnknown,
  //       typeNever,
  //       typeFunction,
  //     };

  String get kNull;
  String get kTrue;
  String get kFalse;

  String get kVar;
  String get kFinal;
  String get kLate;
  String get kConst;
  String get kDelete;

  Set<String> get destructuringDeclarationMark => {
        listStart,
        structStart,
      };

  /// Variable declaration keyword
  Set<String> get variableDeclarationKeywords => {
        kVar,
        kFinal,
        kConst,
        kLate,
      };

  /// Variable declaration keyword
  /// used in for statement's declaration part
  Set<String> get forDeclarationKeywords => {
        kVar,
        kFinal,
      };

  String get kType;
  String get kTypedef;
  String get kTypeof;

  String get kImport;
  String get kExport;
  String get kFrom;

  String get kAssert;
  String get kAs;
  String get kNamespace;
  String get kClass;
  String get kEnum;
  String get kFun;
  String get kStruct;
  String get kThis;
  String get kSuper;

  Set<String> get redirectingConstructorCallKeywords => {kThis, kSuper};

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
  String get kNew;
  String get kFactory;
  String get kGet;
  String get kSet;
  String get kAsync;

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

  /// reserved keywords, cannot used as identifier names
  Set<String> get keywords => {
        kNull,
        kVar,
        kFinal,
        kLate,
        kConst,
        kDelete,
        kAssert,
        kType,
        kTypeof,
        kClass,
        kExtends,
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

  String get indent;

  String get decimalPoint;

  String get variadicArgs;

  String get spreadSyntax;

  String get omittedMark;

  String get everythingMark;

  String get functionReturnTypeIndicator;

  String get whenBranchIndicator;

  String get functionSingleLineBodyIndicator;

  String get nullableMemberGet;

  String get memberGet;

  String get nullableSubGet;

  String get subGetStart;

  String get subGetEnd;

  String get nullableFunctionArgumentCall;

  String get functionParameterStart;

  String get functionParameterEnd;

  String get nullableTypePostfix;

  String get postIncrement;

  String get postDecrement;

  /// postfix operators
  Set<String> get unaryPostfixs => {
        nullableMemberGet,
        memberGet,
        nullableSubGet,
        subGetStart,
        nullableFunctionArgumentCall,
        functionParameterStart,
        postIncrement,
        postDecrement,
      };

  /// prefix operators that modify the value
  Set<String> get unaryPrefixsThatChangeTheValue => {
        preIncrement,
        preDecrement,
      };

  String get logicalNot;

  String get negative;

  String get preIncrement;

  String get preDecrement;

  Set<String> get unaryPrefixs => {
        logicalNot,
        negative,
        preIncrement,
        preDecrement,
        kTypeof,
        kAwait,
      };

  String get multiply;

  String get devide;

  String get truncatingDevide;

  String get modulo;

  Set<String> get multiplicatives => {
        multiply,
        devide,
        truncatingDevide,
        modulo,
      };

  String get add;

  String get subtract;

  Set<String> get additives => {
        add,
        subtract,
      };

  String get greater;

  String get greaterOrEqual;

  String get lesser;

  String get lesserOrEqual;

  Set<String> get logicalRelationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
      };

  Set<String> get typeRelationals => {kAs, kIs};

  Set<String> get setRelationals => {kIn};

  String get equal;

  String get notEqual;

  Set<String> get equalitys => {
        equal,
        notEqual,
      };

  String get ifNull;

  String get logicalOr;

  String get logicalAnd;

  String get ternaryThen;

  String get ternaryElse;

  String get assign;

  String get assignAdd;

  String get assignSubtract;

  String get assignMultiply;

  String get assignDevide;

  String get assignTruncatingDevide;

  String get assignIfNull;

  /// assign operators
  Set<String> get assignments => {
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignTruncatingDevide,
        assignIfNull,
      };

  String get comma;

  String get constructorInitializationListIndicator;

  String get namedArgumentValueIndicator;

  String get typeIndicator;

  String get structValueIndicator;

  /// ';'
  String get endOfStatementMark;

  String get stringStart1;

  String get stringEnd1;

  String get stringStart2;

  String get stringEnd2;

  String get identifierStart;

  String get identifierEnd;

  String get groupExprStart;

  String get groupExprEnd;

  String get codeBlockStart;

  String get codeBlockEnd;

  String get structStart;

  String get structEnd;

  String get listStart;

  String get listEnd;

  String get optionalPositionalParameterStart;

  String get optionalPositionalParameterEnd;

  String get namedParameterStart;

  String get namedParameterEnd;

  String get externalFunctionTypeDefStart;

  String get externalFunctionTypeDefEnd;

  String get typeListStart;

  String get typeListEnd;

  String get importExportListStart;

  String get importExportListEnd;

  /// Token that are not identifers.
  List<String> get punctuations => [
        decimalPoint,
        variadicArgs,
        spreadSyntax,
        functionReturnTypeIndicator,
        whenBranchIndicator,
        functionSingleLineBodyIndicator,
        nullableMemberGet,
        memberGet,
        nullableSubGet,
        subGetStart,
        subGetEnd,
        nullableFunctionArgumentCall,
        functionParameterStart,
        functionParameterEnd,
        nullableTypePostfix,
        postIncrement,
        postDecrement,
        logicalNot,
        negative,
        preIncrement,
        preDecrement,
        multiply,
        devide,
        truncatingDevide,
        modulo,
        add,
        subtract,
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        equal,
        notEqual,
        ifNull,
        logicalOr,
        logicalAnd,
        ternaryThen,
        ternaryElse,
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignTruncatingDevide,
        assignIfNull,
        comma,
        constructorInitializationListIndicator,
        namedArgumentValueIndicator,
        typeIndicator,
        structValueIndicator,
        endOfStatementMark,
        stringStart1,
        stringEnd1,
        stringStart2,
        stringEnd2,
        identifierStart,
        identifierEnd,
        groupExprStart,
        groupExprEnd,
        codeBlockStart,
        codeBlockEnd,
        codeBlockStart,
        codeBlockEnd,
        structStart,
        structEnd,
        listStart,
        listEnd,
        optionalPositionalParameterStart,
        optionalPositionalParameterEnd,
        namedParameterStart,
        namedParameterEnd,
        externalFunctionTypeDefStart,
        externalFunctionTypeDefEnd,
        typeListStart,
        typeListEnd,
      ];

  /// Marker for group start and end.
  // Map<String, String> get groupClosings => {
  //       subGetStart: subGetEnd,
  //       functionCallArgumentStart: functionCallArgumentEnd,
  //       groupExprStart: groupExprEnd,
  //       codeBlockStart: codeBlockEnd,
  //       declarationBlockStart: declarationBlockEnd,
  //       structStart: structEnd,
  //       listStart: listEnd,
  //       optionalPositionalParameterStart: optionalPositionalParameterEnd,
  //       namedParameterStart: namedParameterEnd,
  //       externalFunctionTypeDefStart: externalFunctionTypeDefEnd,
  //       typeParameterStart: typeParameterEnd,
  //     };

  /// Print an object to a string.
  String stringify(dynamic object, {bool asStringLiteral = false});

  String getBaseTypeId(String typeString) {
    final argsStart = typeString.indexOf(typeListStart);
    if (argsStart != -1) {
      return typeString.substring(0, argsStart);
    } else {
      return typeString;
    }
  }

  bool isPrivate(String id) => id.startsWith(privatePrefix);
}
