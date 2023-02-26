part 'locales/english.dart';
part 'locales/simplified_chinese.dart';

/// An abstract interface for a locale that contains error messages.
abstract class HTLocale {
  static HTLocale current = HTLocaleEnglish();

  String get percentageMark;

  String get scriptStackTrace;
  String get externalStackTrace;

  String get errorBytecode;
  String get errorVersion;
  String get errorAssertionFailed;
  String get errorUnkownSourceType;
  String get errorImportListOnNonHetuSource;
  String get errorExportNonHetuSource;

  // syntactic errors
  String get errorUnexpectedToken;
  String get errorUnexpected;
  String get errorDelete;
  String get errorExternal;
  String get errorNestedClass;
  String get errorConstInClass;
  String get errorMisplacedThis;
  String get errorMisplacedSuper;
  String get errorMisplacedReturn;
  String get errorMisplacedContinue;
  String get errorMisplacedBreak;
  String get errorSetterArity;
  String get errorUnexpectedEmptyList;
  String get errorExtendsSelf;
  String get errorMissingFuncBody;
  String get errorExternalCtorWithReferCtor;
  String get errorResourceDoesNotExist;
  String get errorSourceProviderError;
  String get errorNotAbsoluteError;
  String get errorInvalidDeclTypeOfValue;
  String get errorInvalidLeftValue;
  String get errorNullableAssign;
  String get errorPrivateMember;
  String get errorConstMustInit;
  String get errorAwaitExpression;

  // compile time errors
  String get errorDefined;
  String get errorDefinedImportSymbol;
  String get errorOutsideThis;
  String get errorNotMember;
  String get errorNotClass;
  String get errorAbstracted;

  // runtime errors
  String get errorUnsupported;
  String get errorUnknownOpCode;
  String get errorNotInitialized;
  String get errorUndefined;
  String get errorUndefinedExternal;
  String get errorUnknownTypeName;
  String get errorUndefinedOperator;
  String get errorNotNewable;
  String get errorNotCallable;
  String get errorUndefinedMember;
  String get errorUninitialized;
  String get errorCondition;
  String get errorNullObject;
  String get errorNullSubSetKey;
  String get errorSubGetKey;
  String get errorOutOfRange;
  String get errorAssignType;
  String get errorImmutable;
  String get errorNotType;
  String get errorArgType;
  String get errorArgInit;
  String get errorReturnType;
  String get errorStringInterpolation;
  String get errorArity;
  String get errorExternalVar;
  String get errorBytesSig;
  String get errorCircleInit;
  String get errorNamedArg;
  String get errorIterable;
  String get errorUnkownValueType;
  String get errorTypeCast;
  String get errorCastee;
  String get errorNotSuper;
  String get errorStructMemberId;
  String get errorUnresolvedNamedStruct;
  String get errorBinding;
  String get errorNotStruct;

  // Analysis errors
  String get errorConstValue;
  String get errorImportSelf;
}
