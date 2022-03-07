import 'locales.dart';

abstract class HTLocalization {
  static HTLocale data = HTLocaleEnglish();

  void setLocale(String locale) {
    switch (locale) {
      case 'simplified_chinese':
        data = HTLocaleSimplifiedChinese();
        break;
      case 'english':
      default:
        data = HTLocaleEnglish();
    }
  }

  static String get errorBytecode => data.errorBytecode;
  static String get errorVersion => data.errorVersion;
  static String get errorAssertionFailed => data.errorAssertionFailed;
  static String get errorUnkownSourceType => data.errorUnkownSourceType;
  static String get errorImportListOnNonHetuSource =>
      data.errorImportListOnNonHetuSource;
  static String get errorExportNonHetuSource => data.errorExportNonHetuSource;

  // syntactic errors
  static String get errorUnexpected => data.errorUnexpected;
  static String get errorDelete => data.errorDelete;
  static String get errorExternal => data.errorExternal;
  static String get errorNestedClass => data.errorNestedClass;
  static String get errorConstInClass => data.errorConstInClass;
  static String get errorOutsideReturn => data.errorOutsideReturn;
  static String get errorSetterArity => data.errorSetterArity;
  static String get errorExternalMember => data.errorExternalMember;
  static String get errorEmptyTypeArgs => data.errorEmptyTypeArgs;
  static String get errorEmptyImportList => data.errorEmptyImportList;
  static String get errorExtendsSelf => data.errorExtendsSelf;
  static String get errorMissingFuncBody => data.errorMissingFuncBody;
  static String get errorExternalCtorWithReferCtor =>
      data.errorExternalCtorWithReferCtor;
  static String get errorNonCotrWithReferCtor => data.errorNonCotrWithReferCtor;
  static String get errorSourceProviderError => data.errorSourceProviderError;
  static String get errorNotAbsoluteError => data.errorNotAbsoluteError;
  static String get errorInvalidLeftValue => data.errorInvalidLeftValue;
  static String get errorNullableAssign => data.errorNullableAssign;
  static String get errorPrivateMember => data.errorPrivateMember;
  static String get errorConstMustBeStatic => data.errorConstMustBeStatic;
  static String get errorConstMustInit => data.errorConstMustInit;
  static String get errorDuplicateLibStmt => data.errorDuplicateLibStmt;
  static String get errorNotConstValue => data.errorNotConstValue;

  // compile time errors
  static String get errorDefined => data.errorDefined;
  static String get errorOutsideThis => data.errorOutsideThis;
  static String get errorNotMember => data.errorNotMember;
  static String get errorNotClass => data.errorNotClass;
  static String get errorAbstracted => data.errorAbstracted;
  static String get errorInterfaceCtor => data.errorInterfaceCtor;
  static String get errorConstValue => data.errorConstValue;

  // runtime errors
  static String get errorUnsupported => data.errorUnsupported;
  static String get errorUnknownOpCode => data.errorUnknownOpCode;
  static String get errorNotInitialized => data.errorNotInitialized;
  static String get errorUndefined => data.errorUndefined;
  static String get errorUndefinedExternal => data.errorUndefinedExternal;
  static String get errorUnknownTypeName => data.errorUnknownTypeName;
  static String get errorUndefinedOperator => data.errorUndefinedOperator;
  static String get errorNotCallable => data.errorNotCallable;
  static String get errorUndefinedMember => data.errorUndefinedMember;
  static String get errorUninitialized => data.errorUninitialized;
  static String get errorCondition => data.errorCondition;
  static String get errorNullObject => data.errorNullObject;
  static String get errorNullSubSetKey => data.errorNullSubSetKey;
  static String get errorSubGetKey => data.errorSubGetKey;
  static String get errorOutOfRange => data.errorOutOfRange;
  static String get errorAssignType => data.errorAssignType;
  static String get errorImmutable => data.errorImmutable;
  static String get errorNotType => data.errorNotType;
  static String get errorArgType => data.errorArgType;
  static String get errorArgInit => data.errorArgInit;
  static String get errorReturnType => data.errorReturnType;
  static String get errorStringInterpolation => data.errorStringInterpolation;
  static String get errorArity => data.errorArity;
  static String get errorExternalVar => data.errorExternalVar;
  static String get errorBytesSig => data.errorBytesSig;
  static String get errorCircleInit => data.errorCircleInit;
  static String get errorNamedArg => data.errorNamedArg;
  static String get errorIterable => data.errorIterable;
  static String get errorUnkownValueType => data.errorUnkownValueType;
  static String get errorTypeCast => data.errorTypeCast;
  static String get errorCastee => data.errorCastee;
  static String get errorNotSuper => data.errorNotSuper;
  static String get errorStructMemberId => data.errorStructMemberId;
  static String get errorUnresolvedNamedStruct =>
      data.errorUnresolvedNamedStruct;
  static String get errorBinding => data.errorBinding;
}
