import 'vm.dart';
import 'bytecode.dart' show GotoInfo;
import '../variable.dart';
import '../type.dart';
import '../errors.dart';
import '../lexicon.dart';
import '../class.dart';

/// Bytecode implementation of [HTVariable].
class HTBytecodeVariable extends HTVariable with GotoInfo, HetuRef {
  /// Whether this variable have [HTType].
  final bool isDynamic;

  /// Whether this variable is immutable.
  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTType? _declType;

  /// The [HTType] of this variable, will be used to
  /// determine wether an assignment is legal.
  HTType? get declType => _declType;

  /// Create a standard [HTBytecodeVariable].
  ///
  /// A [HTVariable] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be used within a script.
  HTBytecodeVariable(String id, Hetu interpreter, String moduleUniqueKey,
      {String? classId,
      dynamic value,
      HTType? declType,
      int? definitionIp,
      int? line,
      int? column,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            classId: classId,
            value: value,
            getter: getter,
            setter: setter,
            isExtern: isExtern,
            isMember: isMember,
            isStatic: isStatic) {
    this.interpreter = interpreter;
    this.moduleUniqueKey = moduleUniqueKey;
    this.definitionIp = definitionIp;
    this.line = line;
    this.column = column;

    if (declType == null) {
      if (definitionIp == null) {
        _declType = HTType.ANY;
      } else {
        // 初始化时也会尝试对 _declType 赋值
        // TODO: 这里挪到 vm 里面进行？
        // initialize();
      }
    } else {
      _declType = declType;
    }
  }

  /// Initialize this variable with its declared initializer bytecode
  @override
  void initialize() {
    if (isInitialized) return;

    // initialize the declared type if it's a class name.
    if (_declType != null &&
        _declType is! HTFunctionType &&
        _declType is! HTInstanceType) {
      final typeName = _declType!.typeName;
      if (!(HTLexicon.primitiveType.contains(typeName))) {
        final typeDef = interpreter.curNamespace.fetch(_declType!.typeName,
            from: interpreter.curNamespace.fullName);
        if (typeDef is HTClass) {
          _declType = HTInstanceType.fromClass(typeDef,
              typeArgs: _declType!.typeArgs, isNullable: _declType!.isNullable);
        } else {
          // typeDef is a function type
          _declType = typeDef;
        }
      }
    }

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleUniqueKey: moduleUniqueKey,
            ip: definitionIp!,
            namespace: closure);

        assign(initVal);

        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  /// Assign a new value to this variable,
  /// will perform [HTType] check during this process.
  @override
  void assign(dynamic value) {
    if (_declType != null) {
      final encapsulation = interpreter.encapsulate(value);
      final valueType = encapsulation.rtType;
      if (valueType.isNotA(_declType!)) {
        throw HTError.typeCheck(id, valueType.toString(), _declType.toString());
      }
    } else if (!isDynamic && value != null) {
      _declType = interpreter.encapsulate(value).rtType;
    }

    super.assign(value);
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  @override
  HTBytecodeVariable clone() =>
      HTBytecodeVariable(id, interpreter, moduleUniqueKey,
          classId: classId,
          value: value,
          declType: declType,
          definitionIp: definitionIp,
          line: line,
          column: column,
          getter: getter,
          setter: setter,
          isDynamic: isDynamic,
          isExtern: isExtern,
          isImmutable: isImmutable,
          isMember: isMember,
          isStatic: isStatic);
}

/// An implementation of [HTVariable] for function parameter declaration.
class HTBytecodeParameter extends HTBytecodeVariable {
  late final HTParameterType paramType;

  /// Create a standard [HTBytecodeParameter].
  HTBytecodeParameter(String id, Hetu interpreter, String moduleUniqueKey,
      {dynamic value,
      HTType? declType,
      int? definitionIp,
      int? line,
      int? column,
      bool isOptional = false,
      bool isNamed = false,
      bool isVariadic = false})
      : super(id, interpreter, moduleUniqueKey,
            value: value,
            declType: declType,
            definitionIp: definitionIp,
            line: line,
            column: column,
            isImmutable: true) {
    final paramDeclType = declType ?? HTType.ANY;
    paramType = HTParameterType(paramDeclType.typeName,
        typeArgs: paramDeclType.typeArgs,
        isNullable: paramDeclType.isNullable,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }

  @override
  HTBytecodeParameter clone() {
    return HTBytecodeParameter(id, interpreter, moduleUniqueKey,
        value: value,
        declType: declType,
        definitionIp: definitionIp,
        line: line,
        column: column,
        isOptional: paramType.isOptional,
        isNamed: paramType.isNamed,
        isVariadic: paramType.isVariadic);
  }
}
