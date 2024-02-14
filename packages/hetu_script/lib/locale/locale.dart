import 'package:recase/recase.dart';

part 'locales/english.dart';
part 'locales/simplified_chinese.dart';

/// An abstract interface for a locale that contains error messages.
abstract class HTLocale {
  static HTLocale current = HTLocaleEnglish();

  String get percentageMark;

  String get scriptStackTrace;
  String get externalStackTrace;

  // Semantic element names.

  String get compilation;
  String get source;
  String get namespace;

  String get global;

  String get keyword;
  String get identifier;
  String get punctuation;

  String get module;

  String get statement;
  String get expression;
  String get primaryExpression;

  String get comment;
  String get emptyLine;
  String get empty;

  String get declarationStatement;
  String get thenBranch;
  String get elseBranch;
  String get caseBranch;
  String get function;
  String get functionCall;
  String get functionDefinition;
  String get asyncFunction;
  String get constructor;
  String get constructorCall;
  String get factory;
  String get classDefinition;
  String get structDefinition;

  String get literalNull;
  String get literalBoolean;
  String get literalInteger;
  String get literalFloat;
  String get literalString;
  String get stringInterpolation;
  String get literalList;
  String get literalFunction;
  String get literalStruct;
  String get literalStructField;

  String get spreadExpression;
  String get rangeExpression;
  String get groupExpression;
  String get commaExpression;
  String get inOfExpression;

  String get typeParameters;
  String get typeArguments;
  String get typeName;
  String get typeExpression;
  String get intrinsicTypeExpression;
  String get nominalTypeExpression;
  String get literalTypeExpression;
  String get unionTypeExpression;
  String get paramTypeExpression;
  String get functionTypeExpression;
  String get fieldTypeExpression;
  String get structuralTypeExpression;
  String get genericTypeParamExpression;

  String get identifierExpression;
  String get unaryPrefixExpression;
  String get unaryPostfixExpression;
  String get assignExpression;
  String get binaryExpression;
  String get ternaryExpression;
  String get callExpression;
  String get thisExpression;
  String get closureExpression;
  String get subGetExpression;
  String get subSetExpression;
  String get memberGetExpression;
  String get memberSetExpression;
  String get ifExpression;
  String get forExpressionInit;
  String get forExpression;
  String get forRangeExpression;

  String get constantDeclaration;
  String get variableDeclaration;
  String get destructuringDeclaration;
  String get parameterDeclaration;
  String get namespaceDeclaration;
  String get classDeclaration;
  String get enumDeclaration;
  String get typeAliasDeclaration;
  String get returnType;
  String get redirectingFunctionDefinition;
  String get redirectingConstructor;
  String get functionDeclaration;
  String get structDeclaration;

  String get libraryStatement;
  String get importStatement;
  String get exportStatement;
  String get importSymbols;
  String get exportSymbols;
  String get expressionStatement;
  String get blockStatement;
  String get assertStatement;
  String get throwStatement;
  String get returnStatement;
  String get breakStatement;
  String get continueStatement;
  String get doStatement;
  String get whileStatement;
  String get switchStatement;
  String get deleteStatement;
  String get deleteMemberStatement;
  String get deleteSubMemberStatement;

  // error related info
  String get file;
  String get line;
  String get column;
  String get errorType;
  String get message;

  String getErrorType(String errType);

  // generic errors
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
  String get errorAwaitWithoutAsync;
  String get errorNullableAssign;
  String get errorPrivateMember;
  String get errorConstMustInit;
  String get errorAwaitExpression;
  String get errorGetterParam;

  // compile time errors
  String get errorDefined;
  String get errorDefinedImportSymbol;
  String get errorOutsideThis;
  String get errorNotMember;
  String get errorNotClass;
  String get errorAbstracted;
  String get errorAbstractFunction;

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
