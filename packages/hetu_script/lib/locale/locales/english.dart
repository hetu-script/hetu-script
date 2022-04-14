part of '../locale.dart';

class HTLocaleEnglish implements HTLocale {
  @override
  final String percentageMark = '%';

  @override
  final String scriptStackTrace = 'Hetu stack trace';
  @override
  final String externalStackTrace = 'Dart stack trace';

  @override
  final String errorBytecode = 'Unrecognizable bytecode.';
  @override
  final String errorVersion =
      'Incompatible version - bytecode: [{0}], interpreter: [{1}].';
  @override
  final String errorAssertionFailed = "Assertion failed on '{0}'.";
  @override
  final String errorUnkownSourceType = 'Unknown source type: [{0}].';
  @override
  final String errorImportListOnNonHetuSource =
      'Cannot import list from a non hetu source.';
  @override
  final String errorExportNonHetuSource = 'Cannot export a non hetu source.';

  // syntactic errors
  @override
  final String errorUnexpected = 'Expected [{0}], met [{1}].';
  @override
  final String errorDelete =
      'Can only delete a local variable or a struct member.';
  @override
  final String errorExternal = 'External [{0}] is not allowed.';
  @override
  final String errorNestedClass = 'Nested class within another nested class.';
  @override
  final String errorConstInClass = 'Const value in class must be also static.';
  @override
  final String errorOutsideReturn =
      'Unexpected return statement outside of a function.';
  @override
  final String errorSetterArity =
      'Setter function must have exactly one parameter.';
  @override
  final String errorEmptyTypeArgs = 'Empty type arguments.';
  @override
  final String errorEmptyImportList = 'Empty import list.';
  @override
  final String errorExtendsSelf = 'Class try to extends itself.';
  @override
  final String errorMissingFuncBody = 'Missing function definition of [{0}].';
  @override
  final String errorExternalCtorWithReferCtor =
      'Unexpected refer constructor on external constructor.';
  @override
  final String errorSourceProviderError =
      'Context error: could not load file: [{0}].';
  @override
  final String errorNotAbsoluteError =
      'Adding source failed, not a absolute path: [{0}].';
  @override
  final String errorInvalidLeftValue = 'Value cannot be assigned.';
  @override
  final String errorNullableAssign = 'Cannot assign to a nullable value.';
  @override
  final String errorPrivateMember = 'Could not acess private member [{0}].';
  @override
  final String errorConstMustInit =
      'Constant declaration [{0}] must be initialized.';

  // compile time errors
  @override
  final String errorDefined = '[{0}] is already defined.';
  @override
  final String errorOutsideThis =
      'Unexpected this expression outside of a function.';
  @override
  final String errorNotMember = '[{0}] is not a class member of [{1}].';
  @override
  final String errorNotClass = '[{0}] is not a class.';
  @override
  final String errorAbstracted = 'Cannot create instance from abstract class.';
  @override
  final String errorConstValue =
      'Const declaration [{0}]\'s initializer is not a constant expression.';

  // runtime errors
  @override
  final String errorUnsupported = 'Unsupported operation: [{0}].';
  @override
  final String errorUnknownOpCode = 'Unknown opcode [{0}].';
  @override
  final String errorNotInitialized = '[{0}] has not yet been initialized.';
  @override
  final String errorUndefined = 'Undefined identifier [{0}].';
  @override
  final String errorUndefinedExternal = 'Undefined external identifier [{0}].';
  @override
  final String errorUnknownTypeName = 'Unknown type name: [{0}].';
  @override
  final String errorUndefinedOperator = 'Undefined operator: [{0}].';
  @override
  final String errorNotNewable = 'Can not use new operator on [{0}].';
  @override
  final String errorNotCallable = '[{0}] is not callable.';
  @override
  final String errorUndefinedMember = '[{0}] isn\'t defined for the class.';
  @override
  final String errorUninitialized = 'Varialbe [{0}] is not initialized yet.';
  @override
  final String errorCondition =
      'Condition expression must evaluate to type [bool]';
  @override
  final String errorNullObject = 'Calling method [{1}] on null object [{0}].';
  @override
  final String errorNullSubSetKey = 'Sub set key is null.';
  @override
  final String errorSubGetKey = 'Sub get key [{0}] is not of type [int]';
  @override
  final String errorOutOfRange = 'Index [{0}] is out of range [{1}].';
  @override
  final String errorAssignType =
      'Variable [{0}] with type [{2}] can\'t be assigned with type [{1}].';
  @override
  final String errorImmutable = '[{0}] is immutable.';
  @override
  final String errorNotType = '[{0}] is not a type.';
  @override
  final String errorArgType =
      'Argument [{0}] of type [{1}] doesn\'t match parameter type [{2}].';
  @override
  final String errorArgInit =
      'Only optional or named arguments can have initializer.';
  @override
  final String errorReturnType =
      '[{0}] can\'t be returned from function [{1}] with return type [{2}].';
  @override
  final String errorStringInterpolation =
      'String interpolation has to be a single expression.';
  @override
  final String errorArity =
      'Number of arguments [{0}] doesn\'t match function [{1}]\'s parameter requirement [{2}].';
  @override
  final String errorExternalVar = 'External variable is not allowed.';
  @override
  final String errorBytesSig = 'Unknown bytecode signature.';
  @override
  final String errorCircleInit =
      'Variable [{0}]\'s initializer depend on itself.';
  @override
  final String errorNamedArg = 'Undefined named parameter: [{0}].';
  @override
  final String errorIterable = '[{0}] is not Iterable.';
  @override
  final String errorUnkownValueType = 'Unkown OpCode value type: [{0}].';
  @override
  final String errorTypeCast = 'Type [{0}] cannot be cast into type [{1}].';
  @override
  final String errorCastee = 'Illegal cast target [{0}].';
  @override
  final String errorNotSuper = '[{0}] is not a super class of [{1}].';
  @override
  final String errorStructMemberId =
      'Struct member id should be symbol or string.';
  @override
  final String errorUnresolvedNamedStruct =
      'Cannot create struct object from unresolved prototype [{0}].';
  @override
  final String errorBinding =
      'Binding is not allowed on non-literal function or non-struct object.';
  @override
  final String errorNotStruct =
      'Value is not a struct literal, which is needed.';
}
