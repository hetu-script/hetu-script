import 'locales.dart';

abstract class HTLocalization {
  static HTLocale locale = HTLocaleEnglish();

  static String get percentageMark => locale.percentageMark;

  static String get errorBytecode => locale.errorBytecode;
  static String get errorVersion => locale.errorVersion;
  static String get errorAssertionFailed => locale.errorAssertionFailed;
  static String get errorUnkownSourceType => locale.errorUnkownSourceType;
  static String get errorImportListOnNonHetuSource =>
      locale.errorImportListOnNonHetuSource;
  static String get errorExportNonHetuSource => locale.errorExportNonHetuSource;

  // syntactic errors
  static String get errorUnexpected => locale.errorUnexpected;
  static String get errorDelete => locale.errorDelete;
  static String get errorExternal => locale.errorExternal;
  static String get errorNestedClass => locale.errorNestedClass;
  static String get errorConstInClass => locale.errorConstInClass;
  static String get errorOutsideReturn => locale.errorOutsideReturn;
  static String get errorSetterArity => locale.errorSetterArity;
  static String get errorEmptyTypeArgs => locale.errorEmptyTypeArgs;
  static String get errorEmptyImportList => locale.errorEmptyImportList;
  static String get errorExtendsSelf => locale.errorExtendsSelf;
  static String get errorMissingFuncBody => locale.errorMissingFuncBody;
  static String get errorExternalCtorWithReferCtor =>
      locale.errorExternalCtorWithReferCtor;
  static String get errorSourceProviderError => locale.errorSourceProviderError;
  static String get errorNotAbsoluteError => locale.errorNotAbsoluteError;
  static String get errorInvalidLeftValue => locale.errorInvalidLeftValue;
  static String get errorNullableAssign => locale.errorNullableAssign;
  static String get errorPrivateMember => locale.errorPrivateMember;
  static String get errorConstMustInit => locale.errorConstMustInit;

  // compile time errors
  static String get errorDefined => locale.errorDefined;
  static String get errorOutsideThis => locale.errorOutsideThis;
  static String get errorNotMember => locale.errorNotMember;
  static String get errorNotClass => locale.errorNotClass;
  static String get errorAbstracted => locale.errorAbstracted;
  static String get errorConstValue => locale.errorConstValue;

  // runtime errors
  static String get errorUnsupported => locale.errorUnsupported;
  static String get errorUnknownOpCode => locale.errorUnknownOpCode;
  static String get errorNotInitialized => locale.errorNotInitialized;
  static String get errorUndefined => locale.errorUndefined;
  static String get errorUndefinedExternal => locale.errorUndefinedExternal;
  static String get errorUnknownTypeName => locale.errorUnknownTypeName;
  static String get errorUndefinedOperator => locale.errorUndefinedOperator;
  static String get errorNotCallable => locale.errorNotCallable;
  static String get errorUndefinedMember => locale.errorUndefinedMember;
  static String get errorUninitialized => locale.errorUninitialized;
  static String get errorCondition => locale.errorCondition;
  static String get errorNullObject => locale.errorNullObject;
  static String get errorNullSubSetKey => locale.errorNullSubSetKey;
  static String get errorSubGetKey => locale.errorSubGetKey;
  static String get errorOutOfRange => locale.errorOutOfRange;
  static String get errorAssignType => locale.errorAssignType;
  static String get errorImmutable => locale.errorImmutable;
  static String get errorNotType => locale.errorNotType;
  static String get errorArgType => locale.errorArgType;
  static String get errorArgInit => locale.errorArgInit;
  static String get errorReturnType => locale.errorReturnType;
  static String get errorStringInterpolation => locale.errorStringInterpolation;
  static String get errorArity => locale.errorArity;
  static String get errorExternalVar => locale.errorExternalVar;
  static String get errorBytesSig => locale.errorBytesSig;
  static String get errorCircleInit => locale.errorCircleInit;
  static String get errorNamedArg => locale.errorNamedArg;
  static String get errorIterable => locale.errorIterable;
  static String get errorUnkownValueType => locale.errorUnkownValueType;
  static String get errorTypeCast => locale.errorTypeCast;
  static String get errorCastee => locale.errorCastee;
  static String get errorNotSuper => locale.errorNotSuper;
  static String get errorStructMemberId => locale.errorStructMemberId;
  static String get errorUnresolvedNamedStruct =>
      locale.errorUnresolvedNamedStruct;
  static String get errorBinding => locale.errorBinding;
  static String get errorNotStruct => locale.errorNotStruct;
}
