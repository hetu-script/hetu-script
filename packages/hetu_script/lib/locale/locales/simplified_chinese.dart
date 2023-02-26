part of '../locale.dart';

/// The Chinese locale for Hetu, contains error messages.
class HTLocaleSimplifiedChinese implements HTLocale {
  @override
  final String percentageMark = '%';

  @override
  final String scriptStackTrace = '河图函数调用栈';
  @override
  final String externalStackTrace = 'Dart 函数调用栈';

  @override
  final String errorBytecode = '无法识别的字节码文件。';
  @override
  final String errorVersion = '版本冲突！字节码版本：[{0}]，解释器版本：[{1}]。';
  @override
  final String errorAssertionFailed = "断言错误：'{0}'。";
  @override
  final String errorUnkownSourceType = '未知资源类型：[{0}]。';
  @override
  final String errorImportListOnNonHetuSource = '无法在导入非河图代码文件时使用关键字列表。';
  @override
  final String errorExportNonHetuSource = '无法导出非河图代码文件。';

  // syntactic errors
  @override
  final String errorUnexpectedToken = '预期看到：[{0}]，但遇到了意料之外的字符：[{1}]。';
  @override
  final String errorUnexpected =
      '在处理 [{0}] 语句时遇到错误，预期看到：[{1}]，但遇到了意料之外的字符：[{2}]。';
  @override
  final String errorDelete = '只能对普通变量和类成员的标识符使用 delete 关键字。';
  @override
  final String errorExternal = '对 [{0}] 的外部声明无效';
  @override
  final String errorNestedClass = '当前版本不支持嵌套类声明。';
  @override
  final String errorConstInClass = '类成员声明如果是 const，则一定也要是 static 的。';
  @override
  final String errorMisplacedThis = '不能在实例成员函数之外的的场合使用 this 关键字。';
  @override
  final String errorMisplacedSuper = '不能在继承类的实例成员函数之外的的场合使用 super 关键字。';
  @override
  final String errorMisplacedReturn = '不能在非函数定义的场合使用 return 语句。';
  @override
  final String errorMisplacedContinue = '不能在循环语句块之外的场合使用 continue 语句。';
  @override
  final String errorMisplacedBreak = '不能在循环语句块之外的场合使用 break 语句。';
  @override
  final String errorSetterArity = 'setter 函数只能有且只有一个参数。';
  @override
  final String errorUnexpectedEmptyList = '[{0}] 列表是空的。';
  @override
  final String errorExtendsSelf = '类不能继承自己。';
  @override
  final String errorMissingFuncBody = '缺少函数定义：[{0}]。';
  @override
  final String errorExternalCtorWithReferCtor = '外部构造函数不能重定向。';
  @override
  final String errorResourceDoesNotExist = '资源路径 [{0}] 不存在。';
  @override
  final String errorSourceProviderError = '文件系统错误：无法从 [{1}] 所在目录载入资源路径 [{0}]。';
  @override
  final String errorNotAbsoluteError = '添加资源错误，不是绝对路径：[{0}]。';
  @override
  final String errorInvalidDeclTypeOfValue = 'decltypeof 操作符只能用于标识符。';
  @override
  final String errorInvalidLeftValue = '对象无法被赋值。';
  @override
  final String errorNullableAssign = '可空对象无法被赋值。';
  @override
  final String errorPrivateMember = '无法访问私有成员：[{0}]。';
  @override
  final String errorConstMustInit = '常量声明 [{0}] 必须初始化。';
  @override
  final String errorAwaitExpression = '意料之外的 `await` 表达式。';

  // compile time errors
  @override
  final String errorDefined = '标识符 [{0}] 已经被定义过。';
  @override
  final String errorDefinedImportSymbol =
      '从命名空间 [{1}] 中引入的标识符 [{0}]，与从命名空间 [{2}] 中引入过的同名变量冲突。';
  @override
  final String errorOutsideThis = '只能在类的实例成员函数中使用 this 关键字。';
  @override
  final String errorNotMember = '[{0}] 不是类 [{1}] 的成员。';
  @override
  final String errorNotClass = '[{0}] 不是一个类。';
  @override
  final String errorAbstracted = '不能从 abstract class 创建实例。';

  // runtime errors
  @override
  final String errorUnsupported = '在当前河图版本（{1}）中尚不支持[{0}]。';
  @override
  final String errorUnknownOpCode = '未知的字节码操作符：[{0}]。';
  @override
  final String errorNotInitialized = '声明 [{0}] 不能在赋值前使用。';
  @override
  final String errorUndefined = '未定义的标识符：[{0}]。';
  @override
  final String errorUndefinedExternal = '未定义的外部标识符：[{0}]。';
  @override
  final String errorUnknownTypeName = '未定义的类型标识符：[{0}]。';
  @override
  final String errorUndefinedOperator = '未知的操作符：[{0}]。';
  @override
  final String errorNotNewable = '[{0}] 不可作为构造函数调用。';
  @override
  final String errorNotCallable = '[{0}] 不可作为函数调用。';
  @override
  final String errorUndefinedMember = '[{0}] 没有在类中定义。';
  @override
  final String errorUninitialized = '声明 [{0}] 尚未初始化。';
  @override
  final String errorCondition = '条件表达式必须是 [bool] 类型。';
  @override
  final String errorNullObject = '试图在 null 对象 [{0}] 上调用成员函数 [{1}]。';
  @override
  final String errorNullSubSetKey = '下标操作的 key 是 null 对象。';
  @override
  final String errorSubGetKey = '下标操作的 key [{0}] 必须是 [int] 类型。';
  @override
  final String errorOutOfRange = '下标操作的 key [{0}] 超出了范围：[0..{1}]。';
  @override
  final String errorAssignType = '值类型 [{1}] 和变量 [{0}] 声明的类型 [{2}] 不匹配。';
  @override
  final String errorImmutable = '[{0}] 的值不可改变。';
  @override
  final String errorNotType = '[{0}] 不是一个类型。';
  @override
  final String errorArgType = '值类型 [{1}] 和参数 [{0}] 声明的类型 [{2}] 不匹配。';
  @override
  final String errorArgInit = '只有可选参数才可以提供默认值。';
  @override
  final String errorReturnType = '返回值类型 [{0}] 和函数 [{1}] 声明的返回值类型 [{2}] 不匹配。';
  @override
  final String errorStringInterpolation = '字符串插值括号内只能是一个表达式。';
  @override
  final String errorArity = '参数数量 [{0}] 和函数 [{1}] 声明的参数数量 [{2}].';
  @override
  final String errorExternalVar = '不允许声明外部变量。';
  @override
  final String errorBytesSig = '未知的字节码文件。';
  @override
  final String errorCircleInit = '声明 [{0}] 的初始化表达式存在循环依赖。';
  @override
  final String errorNamedArg = '未定义的命名参数：[{0}]。';
  @override
  final String errorIterable = '[{0}] 不是 Iterable 类型。';
  @override
  final String errorUnkownValueType = '未知的字节码数据类型操作符 [{0}]。';
  @override
  final String errorTypeCast = '类型 [{0}] 无法被转换为类型 [{1}]。';
  @override
  final String errorCastee = '非法的 cast 对象：[{0}]。';
  @override
  final String errorNotSuper = '[{0}] 不是 [{1}] 的超类。';
  @override
  final String errorStructMemberId = '对象的 key 只能是字符串或者标识符，但实际的类型是 [{0}]。';
  @override
  final String errorUnresolvedNamedStruct = '对象原型 [{0}] 尚未被解析。';
  @override
  final String errorBinding = 'bind 操作只能用于函数字面量和对象字面量。';
  @override
  final String errorNotStruct = '赋值类型错误：并非结构体。';

  // Analysis errors
  @override
  final String errorConstValue = '常量声明 [{0}] 的初始化表达式不是常量表达式。';

  @override
  final String errorImportSelf = '导入路径不能是代码本身的路径。';
}
