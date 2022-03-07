part of '../locales.dart';

class HTLocaleSimplifiedChinese implements HTLocale {
  @override
  String get errorBytecode => '无法识别的字节码文件。';
  @override
  String get errorVersion => '版本冲突！字节码版本：[{0}]，解释器版本：[{1}]。';
  @override
  String get errorAssertionFailed => "断言错误：'{0}'。";
  @override
  String get errorUnkownSourceType => '未知资源类型：[{0}]。';
  @override
  String get errorImportListOnNonHetuSource => '无法在导入非河图代码文件时使用关键字列表。';
  @override
  String get errorExportNonHetuSource => '无法导出非河图代码文件。';

  // syntactic errors
  @override
  String get errorUnexpected => '意料之外的字符：[{1}]，[{0}]';
  @override
  String get errorDelete =>
      'Can only delete a local variable or a struct member.';
  @override
  String get errorExternal => 'External [{0}] is not allowed.';
  @override
  String get errorNestedClass => 'Nested class within another nested class.';
  @override
  String get errorConstInClass => 'Const value in class must be also static.';
  @override
  String get errorOutsideReturn =>
      'Unexpected return statement outside of a function.';
  @override
  String get errorSetterArity =>
      'Setter function must have exactly one parameter.';
  @override
  String get errorExternalMember =>
      'Non-external class cannot have non-static external members.';
  @override
  String get errorEmptyTypeArgs => 'Empty type arguments.';
  @override
  String get errorEmptyImportList => 'Empty import list.';
  @override
  String get errorExtendsSelf => 'Class try to extends itself.';
  @override
  String get errorMissingFuncBody => 'Missing function definition of [{0}].';
  @override
  String get errorExternalCtorWithReferCtor =>
      'Unexpected refer constructor on external constructor.';
  @override
  String get errorNonCotrWithReferCtor =>
      'Unexpected refer constructor on normal function.';
  @override
  String get errorSourceProviderError =>
      'Context error: could not load file: [{0}].';
  @override
  String get errorNotAbsoluteError =>
      'Adding source failed, not a absolute path: [{0}].';
  @override
  String get errorInvalidLeftValue => 'Value cannot be assigned.';
  @override
  String get errorNullableAssign => 'Cannot assign to a nullable value.';
  @override
  String get errorPrivateMember => 'Could not acess private member [{0}].';
  @override
  String get errorConstMustBeStatic =>
      'Constant class member [{0}] must also be declared as static.';
  @override
  String get errorConstMustInit =>
      'Constant declaration [{0}] must be initialized.';
  @override
  String get errorDuplicateLibStmt => 'Duplicate library statement.';
  @override
  String get errorNotConstValue => 'Constant declared with a non-const value.';

  // compile time errors
  @override
  String get errorDefined => '[{0}] is already defined.';
  @override
  String get errorOutsideThis =>
      'Unexpected this expression outside of a function.';
  @override
  String get errorNotMember => '[{0}] is not a class member of [{1}].';
  @override
  String get errorNotClass => '[{0}] is not a class.';
  @override
  String get errorAbstracted => 'Cannot create instance from abstract class.';
  @override
  String get errorInterfaceCtor => 'Cannot create contructor for interfaces.';
  @override
  String get errorConstValue =>
      'Initializer of const declaration is not constant value.';

  // runtime errors
  @override
  String get errorUnsupported => 'Unsupported operation: [{0}].';
  @override
  String get errorUnknownOpCode => 'Unknown opcode [{0}].';
  @override
  String get errorNotInitialized => '[{0}] has not yet been initialized.';
  @override
  String get errorUndefined => 'Undefined identifier [{0}].';
  @override
  String get errorUndefinedExternal => 'Undefined external identifier [{0}].';
  @override
  String get errorUnknownTypeName => 'Unknown type name: [{0}].';
  @override
  String get errorUndefinedOperator => 'Undefined operator: [{0}].';
  @override
  String get errorNotCallable => '[{0}] is not callable.';
  @override
  String get errorUndefinedMember => '[{0}] isn\'t defined for the class.';
  @override
  String get errorUninitialized => 'Varialbe [{0}] is not initialized yet.';
  @override
  String get errorCondition =>
      'Condition expression must evaluate to type [bool]';
  @override
  String get errorNullObject => 'Calling method [{1}] on null object [{0}].';
  @override
  String get errorNullSubSetKey => 'Sub set key is null.';
  @override
  String get errorSubGetKey => 'Sub get key [{0}] is not of type [int]';
  @override
  String get errorOutOfRange => 'Index [{0}] is out of range [{1}].';
  @override
  String get errorAssignType =>
      'Variable [{0}] with type [{2}] can\'t be assigned with type [{1}].';
  @override
  String get errorImmutable => '[{0}] is immutable.';
  @override
  String get errorNotType => '[{0}] is not a type.';
  @override
  String get errorArgType =>
      'Argument [{0}] of type [{1}] doesn\'t match parameter type [{2}].';
  @override
  String get errorArgInit =>
      'Only optional or named arguments can have initializer.';
  @override
  String get errorReturnType =>
      '[{0}] can\'t be returned from function [{1}] with return type [{2}].';
  @override
  String get errorStringInterpolation =>
      'String interpolation has to be a single expression.';
  @override
  String get errorArity =>
      'Number of arguments [{0}] doesn\'t match function [{1}]\'s parameter requirement [{2}].';
  @override
  String get errorExternalVar => 'External variable is not allowed.';
  @override
  String get errorBytesSig => 'Unknown bytecode signature.';
  @override
  String get errorCircleInit =>
      'Variable [{0}]\'s initializer depend on itself being initialized.';
  @override
  String get errorNamedArg => 'Undefined named parameter: [{0}].';
  @override
  String get errorIterable => '[{0}] is not Iterable.';
  @override
  String get errorUnkownValueType => 'Unkown OpCode value type: [{0}].';
  @override
  String get errorTypeCast => 'Type [{0}] cannot be cast into type [{1}].';
  @override
  String get errorCastee => 'Illegal cast target [{0}].';
  @override
  String get errorNotSuper => '[{0}] is not a super class of [{1}].';
  @override
  String get errorStructMemberId =>
      'Struct member id should be symbol or string.';
  @override
  String get errorUnresolvedNamedStruct =>
      'Cannot create struct object from unresolved prototype [{0}].';
  @override
  String get errorBinding =>
      'Binding is not allowed on non-literal function or non-struct object.';
}
