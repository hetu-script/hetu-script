base class InternalIdentifier {
  static const prototype = r'$prototype';
  static const call = r'$call';
  static const instance = r'$instance';
  static const defaultConstructor = r'$constructor';
  static const namedConstructorPrefix = r'$construct_';
  static const getter = r'$getter_';
  static const setter = r'$setter_';
  static const subGetter = r'$sub_getter_';
  static const subSetter = r'$sub_setter_';

  static const anonymousScript = r'$script';
  static const anonymousClass = r'$class';
  static const anonymousStruct = r'$struct';
  static const anonymousFunction = r'$function';
  static const anonymousBlock = r'$block';

  static const instanceOf = 'instanceOf';
  static const externalType = 'externalType';

  static const namespace = 'namespace';

  static const global = 'global';

  static const keyword = 'keyword';
  static const identifier = 'identifier';
  static const punctuation = 'punctuation';

  static const module = 'module';

  static const statement = 'statement';
  static const expression = 'expression';
  static const primaryExpression = 'primaryExpression';

  static const comment = 'comment';
  static const emptyLine = 'emptyLine';
  static const empty = 'empty';

  static const source = 'source';
  static const compilation = 'compilation';
  static const literalNull = 'literalNull';
  static const literalBoolean = 'literalBoolean';
  static const literalInteger = 'literalInteger';
  static const literalFloat = 'literalFloat';
  static const literalString = 'literalString';
  static const stringInterpolation = 'stringInterpolation';
  static const literalList = 'literalList';

  static const identifierExpression = 'identifierExpression';
  static const spreadExpression = 'spreadExpression';
  static const commaExpression = 'commaExpression';
  static const inOfExpression = 'inOfExpression';
  static const groupExpression = 'groupExpression';
  static const intrinsicTypeExpression = 'intrinsicTypeExpression';
  static const nominalTypeExpression = 'nominalTypeExpression';
  static const paramTypeExpression = 'paramTypeExpression';
  static const functionTypeExpression = 'functionTypeExpression';
  static const fieldTypeExpression = 'fieldTypeExpression';
  static const structuralTypeExpression = 'structuralTypeExpression';
  static const genericTypeParamExpression = 'genericTypeParamExpression';
  static const unaryPrefixExpression = 'unaryPrefixExpression';
  static const unaryPostfixExpression = 'unaryPostfixExpression';
  static const binaryExpression = 'binaryExpression';
  static const ternaryExpression = 'ternaryExpression';
  static const assignExpression = 'assignExpression';
  static const memberGetExpression = 'memberGetExpression';
  static const subGetExpression = 'subGetExpression';
  static const callExpression = 'callExpression';

  static const ifExpression = 'ifExpression';
  static const forExpressionInit = 'forExpressionInit';
  static const forExpression = 'forExpression';
  static const forRangeExpression = 'forRangeExpression';

  static const assertStatement = 'assertStatement';
  static const throwStatement = 'throwStatement';
  static const expressionStatement = 'expressionStatement';
  static const blockStatement = 'blockStatement';
  static const returnStatement = 'returnStatement';
  static const whileStatement = 'whileStatement';
  static const doStatement = 'doStatement';
  static const switchStatement = 'switchStatement';
  static const breakStatement = 'breakStatement';
  static const continueStatement = 'continueStatement';
  static const deleteStatement = 'deleteStatement';
  static const deleteMemberStatement = 'deleteMemberStatement';
  static const deleteSubMemberStatement = 'deleteSubMemberStatement';
  static const exportStatement = 'exportStatement';
  static const importStatement = 'importStatement';

  static const namespaceDeclaration = 'namespaceDeclaration';
  static const typeAliasDeclaration = 'typeAliasDeclaration';
  static const constantDeclaration = 'constantDeclaration';
  static const variableDeclaration = 'variableDeclaration';
  static const destructuringDeclaration = 'destructuringDeclaration';
  static const parameterDeclaration = 'parameterDeclaration';
  static const redirectingConstructor = 'redirectingConstructor';
  static const functionDeclaration = 'functionDeclaration';
  static const classDeclaration = 'classDeclaration';
  static const enumDeclaration = 'enumDeclaration';
  static const structDeclaration = 'structDeclaration';
  static const literalStructField = 'literalStructField';
  static const literalStruct = 'literalStruct';
}
