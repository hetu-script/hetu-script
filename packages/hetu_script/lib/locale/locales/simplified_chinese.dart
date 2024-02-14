part of '../locale.dart';

/// The Chinese locale for Hetu, contains error messages.
class HTLocaleSimplifiedChinese implements HTLocale {
  @override
  String get percentageMark => '%';

  @override
  String get scriptStackTrace => '河图函数调用栈';
  @override
  String get externalStackTrace => 'Dart 函数调用栈';

  // Semantic element names.
  @override
  String get compilation => '打包文件';
  @override
  String get source => '源文件';
  @override
  String get namespace => '命名空间';

  @override
  String get global => '全局';

  @override
  String get keyword => '关键字';
  @override
  String get identifier => '识别符';
  @override
  String get punctuation => '标点符号';

  @override
  String get module => '模块';

  @override
  String get statement => '语句';
  @override
  String get expression => '表达式';
  @override
  String get primaryExpression => '主表达式';

  @override
  String get comment => '注释';
  @override
  String get emptyLine => '空行';
  @override
  String get empty => '空';

  @override
  String get declarationStatement => '声明语句';
  @override
  String get thenBranch => '则(then)分支';
  @override
  String get elseBranch => '否则(else)分支';
  @override
  String get caseBranch => '选择(case)分支';
  @override
  String get function => '函数';
  @override
  String get functionCall => '函数调用';
  @override
  String get functionDefinition => '函数定义';
  @override
  String get asyncFunction => '异步函数';
  @override
  String get constructor => '构造函数';
  @override
  String get constructorCall => '构造函数调用';
  @override
  String get factory => '工厂构造函数';
  @override
  String get classDefinition => '类定义';
  @override
  String get structDefinition => '结构体定义';

  @override
  String get literalNull => '字面值：空(null)';
  @override
  String get literalBoolean => '字面值：布尔(bool)';
  @override
  String get literalInteger => '字面值：整数(int)';
  @override
  String get literalFloat => '字面值：浮点数(float)';
  @override
  String get literalString => '字面值：字符串(string)';
  @override
  String get stringInterpolation => '字面值：插值字符串(string interpolation)';
  @override
  String get literalList => '字面值：数组';
  @override
  String get literalFunction => '字面值：函数';
  @override
  String get literalStruct => '字面值：结构体';
  @override
  String get literalStructField => '字面值：结构体成员';

  @override
  String get spreadExpression => '展开表达式';
  @override
  String get rangeExpression => '范围表达式';
  @override
  String get groupExpression => '括号表达式';
  @override
  String get commaExpression => '逗号表达式';
  @override
  String get inOfExpression => '自动迭代器（in/of）表达式';

  @override
  String get typeParameters => '类型形式参数';
  @override
  String get typeArguments => '类型实际参数';
  @override
  String get typeName => '类型名';
  @override
  String get typeExpression => '类型表达式';
  @override
  String get intrinsicTypeExpression => '内置类型表达式';
  @override
  String get nominalTypeExpression => '具名类型表达式';
  @override
  String get literalTypeExpression => '字面值类型表达式';
  @override
  String get unionTypeExpression => '联合类型表达式';
  @override
  String get paramTypeExpression => '形式参数类型表达式';
  @override
  String get functionTypeExpression => '函数类型表达式';
  @override
  String get fieldTypeExpression => '类成员类型表达式';
  @override
  String get structuralTypeExpression => '结构类型表达式';
  @override
  String get genericTypeParamExpression => '泛型参数类型表达式';

  @override
  String get identifierExpression => '标识符表达式';
  @override
  String get unaryPrefixExpression => '前缀表达式';
  @override
  String get unaryPostfixExpression => '后缀表达式';
  @override
  String get assignExpression => '赋值表达式';
  @override
  String get binaryExpression => '二元运算表达式';
  @override
  String get ternaryExpression => '三元运算表达式';
  @override
  String get callExpression => '函数调用表达式';
  @override
  String get thisExpression => '实例(this)表达式';
  @override
  String get closureExpression => '闭包(closure)表达式';
  @override
  String get subGetExpression => '下标表达式';
  @override
  String get subSetExpression => '下标赋值表达式';
  @override
  String get memberGetExpression => '成员表达式';
  @override
  String get memberSetExpression => '成员赋值表达式';
  @override
  String get ifExpression => '若(if)表达式';
  @override
  String get forExpression => '对于(for)表达式';
  @override
  String get forExpressionInit => '对于(for)表达式初始化';
  @override
  String get forRangeExpression => '自动迭代器对于(for)表达式';

  @override
  String get constantDeclaration => '常量声明';
  @override
  String get variableDeclaration => '变量声明';
  @override
  String get destructuringDeclaration => '解构声明';
  @override
  String get parameterDeclaration => '参数声明';
  @override
  String get namespaceDeclaration => '命名空间声明';
  @override
  String get classDeclaration => '类声明';
  @override
  String get enumDeclaration => '枚举类声明';
  @override
  String get typeAliasDeclaration => '类型声明';
  @override
  String get returnType => '返回值类型';
  @override
  String get redirectingFunctionDefinition => '重定向函数定义';
  @override
  String get redirectingConstructor => '重定向构造函数';
  @override
  String get functionDeclaration => '函数声明';
  @override
  String get structDeclaration => '结构体声明';
  @override
  String get libraryStatement => '库声明';
  @override
  String get importStatement => '导入声明';
  @override
  String get exportStatement => '导出声明';
  @override
  String get importSymbols => '导入对象列表';
  @override
  String get exportSymbols => '导出对象列表';
  @override
  String get expressionStatement => '表达式语句';
  @override
  String get blockStatement => '块语句';
  @override
  String get assertStatement => '断言(assert)语句';
  @override
  String get throwStatement => '抛出异常(throw)语句';
  @override
  String get returnStatement => '返回(return)语句';
  @override
  String get breakStatement => '中断(break)语句';
  @override
  String get continueStatement => '跳过(continue)语句';
  @override
  String get doStatement => '执行块语句';
  @override
  String get whileStatement => '当(while)循环语句';
  @override
  String get switchStatement => '选择语句';
  @override
  String get deleteStatement => '删除语句';
  @override
  String get deleteMemberStatement => '删除成员语句';
  @override
  String get deleteSubMemberStatement => '删除下标语句';

  // error related info
  @override
  String get file => '文件';
  @override
  String get line => '行';
  @override
  String get column => '列';
  @override
  String get errorType => '错误类型';
  @override
  String get message => '详细信息';

  @override
  String getErrorType(String errType) {
    return switch (errType) {
      'TODO' => '待办',
      'HINT' => '提示',
      'LINT' => '格式化',
      'SYNTACTIC_ERROR' => '句法',
      'STATIC_TYPE_WARNING' => '类型分析',
      'STATIC_WARNING' => '静态分析',
      'COMPILE_TIME_ERROR' => '编译',
      'RUNTIME_ERROR' => '运行时',
      'EXTERNAL_ERROR' => '外部',
      _ => 'unknown',
    };
  }

  // generic errors
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
  String get errorUnexpectedToken => '预期看到：[{0}]，但遇到了意料之外的字符：[{1}]。';
  @override
  String get errorUnexpected =>
      '在处理 [{0}] 语句时遇到错误，预期看到：[{1}]，但遇到了意料之外的字符：[{2}]。';
  @override
  String get errorDelete => '只能对普通变量和类成员的标识符使用 delete 关键字。';
  @override
  String get errorExternal => '对 [{0}] 的外部声明无效';
  @override
  String get errorNestedClass => '当前版本不支持嵌套类声明。';
  @override
  String get errorConstInClass => '类成员声明如果是 const，则一定也要是 static 的。';
  @override
  String get errorMisplacedThis => '不能在实例成员函数之外的的场合使用 this 关键字。';
  @override
  String get errorMisplacedSuper => '不能在继承类的实例成员函数之外的的场合使用 super 关键字。';
  @override
  String get errorMisplacedReturn => '不能在非函数定义的场合使用 return 语句。';
  @override
  String get errorMisplacedContinue => '不能在循环语句块之外的场合使用 continue 语句。';
  @override
  String get errorMisplacedBreak => '不能在循环语句块之外的场合使用 break 语句。';
  @override
  String get errorSetterArity => 'setter 函数只能有且只有一个参数。';
  @override
  String get errorUnexpectedEmptyList => '[{0}] 列表是空的。';
  @override
  String get errorExtendsSelf => '类不能继承自己。';
  @override
  String get errorMissingFuncBody => '函数 [{0}] 缺少函数定义。';
  @override
  String get errorExternalCtorWithReferCtor => '外部构造函数不能重定向。';
  @override
  String get errorResourceDoesNotExist => '资源路径 [{0}] 不存在。';
  @override
  String get errorSourceProviderError => '文件系统错误：无法从 [{1}] 所在目录载入资源路径 [{0}]。';
  @override
  String get errorNotAbsoluteError => '添加资源错误，不是绝对路径：[{0}]。';
  @override
  String get errorInvalidDeclTypeOfValue => 'decltypeof 操作符只能用于标识符。';
  @override
  String get errorInvalidLeftValue => '对象无法被赋值。';
  @override
  String get errorAwaitWithoutAsync => '`await` 关键字只能在异步函数中使用。';
  @override
  String get errorNullableAssign => '可空对象无法被赋值。';
  @override
  String get errorPrivateMember => '无法访问私有成员：[{0}]。';
  @override
  String get errorConstMustInit => '常量声明 [{0}] 必须初始化。';
  @override
  String get errorAwaitExpression => '意料之外的 `await` 表达式。';
  @override
  String get errorGetterParam => '意料之外的 `getter` 函数上的参数声明';

  // compile time errors
  @override
  String get errorDefined => '标识符 [{0}] 已经被定义过。';
  @override
  String get errorDefinedImportSymbol =>
      '从命名空间 [{1}] 中引入的标识符 [{0}]，与从命名空间 [{2}] 中引入过的同名变量冲突。';
  @override
  String get errorOutsideThis => '只能在类的实例成员函数中使用 this 关键字。';
  @override
  String get errorNotMember => '[{0}] 不是类 [{1}] 的成员。';
  @override
  String get errorNotClass => '[{0}] 不是一个类。';
  @override
  String get errorAbstracted => '不能从抽象类 [{0}] 创建实例。';
  @override
  String get errorAbstractFunction => '不能调用函数 [{0}]，该函数是抽象函数，或者没有定义函数体。';

  // runtime errors
  @override
  String get errorUnsupported => '在当前河图版本（{1}）中尚不支持[{0}]。';
  @override
  String get errorUnknownOpCode => '未知的字节码操作符：[{0}]。';
  @override
  String get errorNotInitialized => '声明 [{0}] 不能在赋值前使用。';
  @override
  String get errorUndefined => '未定义的标识符：[{0}]。';
  @override
  String get errorUndefinedExternal => '未定义的外部标识符：[{0}]。';
  @override
  String get errorUnknownTypeName => '未定义的类型标识符：[{0}]。';
  @override
  String get errorUndefinedOperator => '未知的操作符：[{0}]。';
  @override
  String get errorNotNewable => '[{0}] 不可作为构造函数调用。';
  @override
  String get errorNotCallable => '[{0}] 不可作为函数调用。';
  @override
  String get errorUndefinedMember => '[{0}] 没有在类中定义。';
  @override
  String get errorUninitialized => '声明 [{0}] 尚未初始化。';
  @override
  String get errorCondition => '条件表达式必须是 [bool] 类型。';
  @override
  String get errorNullObject => '试图在 null 对象 [{0}] 上调用成员函数 [{1}]。';
  @override
  String get errorNullSubSetKey => '下标操作的 key 是 null 对象。';
  @override
  String get errorSubGetKey => '下标操作的 key [{0}] 必须是 [int] 类型。';
  @override
  String get errorOutOfRange => '下标操作的 key [{0}] 超出了范围：[0..{1}]。';
  @override
  String get errorAssignType => '值类型 [{1}] 和变量 [{0}] 声明的类型 [{2}] 不匹配。';
  @override
  String get errorImmutable => '[{0}] 的值不可改变。';
  @override
  String get errorNotType => '[{0}] 不是一个类型。';
  @override
  String get errorArgType => '值类型 [{1}] 和参数 [{0}] 声明的类型 [{2}] 不匹配。';
  @override
  String get errorArgInit => '只有可选参数才可以提供默认值。';
  @override
  String get errorReturnType => '返回值类型 [{0}] 和函数 [{1}] 声明的返回值类型 [{2}] 不匹配。';
  @override
  String get errorStringInterpolation => '字符串插值括号内只能是一个表达式。';
  @override
  String get errorArity => '参数数量 [{0}] 和函数 [{1}] 声明的参数数量 [{2}].';
  @override
  String get errorExternalVar => '不允许声明外部变量。';
  @override
  String get errorBytesSig => '未知的字节码文件。';
  @override
  String get errorCircleInit => '声明 [{0}] 的初始化表达式存在循环依赖。';
  @override
  String get errorNamedArg => '未定义的命名参数：[{0}]。';
  @override
  String get errorIterable => '[{0}] 不是 Iterable 类型。';
  @override
  String get errorUnkownValueType => '未知的字节码数据类型操作符 [{0}]。';
  @override
  String get errorTypeCast => '类型 [{0}] 无法被转换为类型 [{1}]。';
  @override
  String get errorCastee => '非法的 cast 对象：[{0}]。';
  @override
  String get errorNotSuper => '[{0}] 不是 [{1}] 的超类。';
  @override
  String get errorStructMemberId => '对象的 key 只能是字符串或者标识符，但实际的类型是 [{0}]。';
  @override
  String get errorUnresolvedNamedStruct => '对象原型 [{0}] 尚未被解析。';
  @override
  String get errorBinding => 'bind 操作只能用于函数字面量和对象字面量。';
  @override
  String get errorNotStruct => '赋值类型错误：并非结构体。';

  // Analysis errors
  @override
  String get errorConstValue => '常量声明 [{0}] 的初始化表达式不是常量表达式。';

  @override
  String get errorImportSelf => '导入路径不能是代码本身的路径。';
}
