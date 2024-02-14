part of '../locale.dart';

/// The English locale for Hetu, contains error messages.
class HTLocaleEnglish implements HTLocale {
  @override
  String get percentageMark => '%';

  @override
  String get scriptStackTrace => 'Hetu stack trace';
  @override
  String get externalStackTrace => 'Dart stack trace';

  // Semantic element names.
  @override
  String get compilation => 'compilation';
  @override
  String get source => 'source';
  @override
  String get namespace => 'namespace';

  @override
  String get global => 'global';

  @override
  String get keyword => 'keyword';
  @override
  String get identifier => 'identifier';
  @override
  String get punctuation => 'punctuation';

  @override
  String get module => 'source module';

  @override
  String get statement => 'statement';
  @override
  String get expression => 'expression';
  @override
  String get primaryExpression => 'primary expression';

  @override
  String get comment => 'comment';
  @override
  String get emptyLine => 'empty line';
  @override
  String get empty => 'empty';

  @override
  String get declarationStatement => 'declaration statement';
  @override
  String get thenBranch => 'then branch';
  @override
  String get elseBranch => 'else branch';
  @override
  String get caseBranch => 'case branch';
  @override
  String get function => 'function';
  @override
  String get functionCall => 'function call';
  @override
  String get functionDefinition => 'function definition';
  @override
  String get asyncFunction => 'async function';
  @override
  String get constructor => 'constructor';
  @override
  String get constructorCall => 'constructor call';
  @override
  String get factory => 'factory';
  @override
  String get classDefinition => 'class definition';
  @override
  String get structDefinition => 'struct definition';

  @override
  String get literalNull => 'literal null';
  @override
  String get literalBoolean => 'literal boolean';
  @override
  String get literalInteger => 'literal integer';
  @override
  String get literalFloat => 'literal float';
  @override
  String get literalString => 'literal string';
  @override
  String get stringInterpolation => 'string interpolation';
  @override
  String get literalList => 'literal list';
  @override
  String get literalFunction => 'literal function';
  @override
  String get literalStruct => 'literal struct';
  @override
  String get literalStructField => 'literal struct field';

  @override
  String get spreadExpression => 'spread expression';
  @override
  String get rangeExpression => 'range expression';
  @override
  String get groupExpression => 'group expression';
  @override
  String get commaExpression => 'comma expression';
  @override
  String get inOfExpression => 'in expression';

  @override
  String get typeParameters => 'type parameters';
  @override
  String get typeArguments => 'type arguments';
  @override
  String get typeName => 'type name';
  @override
  String get typeExpression => 'type expression';
  @override
  String get intrinsicTypeExpression => 'intrinsic type expression';
  @override
  String get nominalTypeExpression => 'nominal type expression';
  @override
  String get literalTypeExpression => 'literal type expression';
  @override
  String get unionTypeExpression => 'union type expression';
  @override
  String get paramTypeExpression => 'parameter type expression';
  @override
  String get functionTypeExpression => 'function type expression';
  @override
  String get fieldTypeExpression => 'field type expression';
  @override
  String get structuralTypeExpression => 'structural type expression';
  @override
  String get genericTypeParamExpression => 'generic type parameter expression';

  @override
  String get identifierExpression => 'identifier expression';
  @override
  String get unaryPrefixExpression => 'unary prefix expression';
  @override
  String get unaryPostfixExpression => 'unary postfix expression';
  @override
  String get assignExpression => 'assign expression';
  @override
  String get binaryExpression => 'binary expression';
  @override
  String get ternaryExpression => 'ternary expression';
  @override
  String get callExpression => 'call expression';
  @override
  String get thisExpression => 'this expression';
  @override
  String get closureExpression => 'closure expression';
  @override
  String get subGetExpression => 'subscript get expression';
  @override
  String get subSetExpression => 'subscript set expression';
  @override
  String get memberGetExpression => 'member get expression';
  @override
  String get memberSetExpression => 'member set expression';
  @override
  String get ifExpression => 'if expression';
  @override
  String get forExpression => 'for expression';
  @override
  String get forExpressionInit => 'for expression init';
  @override
  String get forRangeExpression => 'for range expression';

  @override
  String get constantDeclaration => 'constant declaration';
  @override
  String get variableDeclaration => 'variable declaration';
  @override
  String get destructuringDeclaration => 'destructuring declaration';
  @override
  String get parameterDeclaration => 'parameter declaration';
  @override
  String get namespaceDeclaration => 'namespace declaration';
  @override
  String get classDeclaration => 'class declaration';
  @override
  String get enumDeclaration => 'enum declaration';
  @override
  String get typeAliasDeclaration => 'type alias declaration';
  @override
  String get returnType => 'return type';
  @override
  String get redirectingFunctionDefinition => 'redirecting function definition';
  @override
  String get redirectingConstructor =>
      'redirecting constructor call expression';
  @override
  String get functionDeclaration => 'function declaration';
  @override
  String get structDeclaration => 'struct declaration';
  @override
  String get libraryStatement => 'library statement';
  @override
  String get importStatement => 'import statement';
  @override
  String get exportStatement => 'export statement';
  @override
  String get importSymbols => 'import symbols';
  @override
  String get exportSymbols => 'export symbols';
  @override
  String get expressionStatement => 'expression statement';
  @override
  String get blockStatement => 'block statement';
  @override
  String get assertStatement => 'assert statement';
  @override
  String get throwStatement => 'throw statement';
  @override
  String get returnStatement => 'return statement';
  @override
  String get breakStatement => 'break statement';
  @override
  String get continueStatement => 'continue statement';
  @override
  String get doStatement => 'do statement';
  @override
  String get whileStatement => 'while statement';
  @override
  String get switchStatement => 'switch statement';
  @override
  String get deleteStatement => 'delete statement';
  @override
  String get deleteMemberStatement => 'delete member statement';
  @override
  String get deleteSubMemberStatement => 'delete subscript member statement';

  // error related info
  @override
  String get file => 'File';
  @override
  String get line => 'Line';
  @override
  String get column => 'Column';
  @override
  String get errorType => 'Error type';
  @override
  String get message => 'Message';

  @override
  String getErrorType(String errType) {
    return ReCase(errType).sentenceCase;
  }

  // generic errors
  @override
  String get errorBytecode => 'Unrecognizable bytecode.';
  @override
  String get errorVersion =>
      'Incompatible version - bytecode: [{0}], interpreter: [{1}].';
  @override
  String get errorAssertionFailed => "Assertion failed on '{0}'.";
  @override
  String get errorUnkownSourceType => 'Unknown source type: [{0}].';
  @override
  String get errorImportListOnNonHetuSource =>
      'Cannot import list from a non hetu source.';
  @override
  String get errorExportNonHetuSource => 'Cannot export a non hetu source.';

  // syntactic errors
  @override
  String get errorUnexpectedToken => 'Expected [{0}], met [{1}].';
  @override
  String get errorUnexpected =>
      'While parsing [{0}], expected [{1}], met [{2}].';
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
  String get errorMisplacedThis =>
      'Unexpected this keyword outside of a instance method.';
  @override
  String get errorMisplacedSuper =>
      'Unexpected super keyword outside of a inherited class\'s instance method.';
  @override
  String get errorMisplacedReturn =>
      'Unexpected return statement outside of a function.';
  @override
  String get errorMisplacedContinue =>
      'Unexpected continue statement outside of a loop.';
  @override
  String get errorMisplacedBreak =>
      'Unexpected break statement outside of a loop.';
  @override
  String get errorSetterArity =>
      'Setter function must have exactly one parameter.';
  @override
  String get errorUnexpectedEmptyList => 'Unexpected empty [{0}] list.';
  @override
  String get errorExtendsSelf => 'Class try to extends itself.';
  @override
  String get errorMissingFuncBody => 'Missing function definition of [{0}].';
  @override
  String get errorExternalCtorWithReferCtor =>
      'Unexpected refer constructor on external constructor.';
  @override
  String get errorResourceDoesNotExist =>
      'Resource with name [{0}] does not exist.';
  @override
  String get errorSourceProviderError =>
      'File system error: Could not load resource [{0}] from path [{1}].';
  @override
  String get errorNotAbsoluteError =>
      'Adding source failed, not a absolute path: [{0}].';
  @override
  String get errorInvalidDeclTypeOfValue =>
      'decltypeof can only be used on identifier.';
  @override
  String get errorInvalidLeftValue => 'Value cannot be assigned.';
  @override
  String get errorAwaitWithoutAsync =>
      '`await` keyword can only be used inside an async function body.';
  @override
  String get errorNullableAssign => 'Cannot assign to a nullable value.';
  @override
  String get errorPrivateMember => 'Could not acess private member [{0}].';
  @override
  String get errorConstMustInit =>
      'Constant declaration [{0}] must be initialized.';
  @override
  String get errorAwaitExpression => 'Unexpected `await` expressions.';
  @override
  String get errorGetterParam =>
      'Unexpected parameter list for getter function.';

  // compile time errors
  @override
  String get errorDefined => '[{0}] is already defined.';
  @override
  String get errorDefinedImportSymbol =>
      'Symbol [{0}] importing from [{1}] is already imported from [{2}].';
  @override
  String get errorOutsideThis =>
      'Unexpected this expression outside of a function.';
  @override
  String get errorNotMember => '[{0}] is not a class member of [{1}].';
  @override
  String get errorNotClass => '[{0}] is not a class.';
  @override
  String get errorAbstracted =>
      'Cannot create instance from abstract class [{0}].';
  @override
  String get errorAbstractFunction => 'Cannot call an abstract function [{0}].';

  // runtime errors
  @override
  String get errorUnsupported =>
      '[{0}] is not supported in currect Hetu version: [{1}].';
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
  String get errorNotNewable => 'Can not use new operator on [{0}].';
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
      'Variable [{0}]\'s initializer depend on itself.';
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
      'Struct member id should be symbol or string, however met id with token type: [{0}].';
  @override
  String get errorUnresolvedNamedStruct =>
      'Cannot create struct object from unresolved prototype [{0}].';
  @override
  String get errorBinding =>
      'Binding is not allowed on non-literal function or non-struct object.';
  @override
  String get errorNotStruct =>
      'Value is not a struct literal, which is needed.';

  // Analysis errors
  @override
  String get errorConstValue =>
      'Const declaration [{0}]\'s initializer is not a constant expression.';

  @override
  String get errorImportSelf => 'Import path is the same to the source itself.';
}
