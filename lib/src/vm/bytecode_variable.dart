import 'vm.dart';
import 'bytecode.dart' show GotoInfo;
import '../variable.dart';
import '../type.dart';
import '../errors.dart';
import '../class.dart';
import '../lexicon.dart';

/// Bytecode implementation of [HTVariable].
class HTBytecodeVariable<T> extends HTVariable<T> with GotoInfo, HetuRef {
  final bool typeInferrence;

  /// Whether this variable is immutable.
  @override
  final bool isImmutable;

  var _isInitializing = false;

  var _isTypeInitialized = false;

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
      T? value,
      HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      Function? getter,
      Function? setter,
      bool isExtern = false,
      this.typeInferrence = false,
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
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (declType != null) {
      _declType = declType;

      if (_declType is HTFunctionType ||
          _declType is HTInstanceType ||
          (HTLexicon.primitiveType.contains(declType.typeName))) {
        _isTypeInitialized = true;
      }
    } else {
      if (!typeInferrence || (definitionIp == null)) {
        _declType = HTType.ANY;
        _isTypeInitialized = true;
      }
    }
  }

  /// initialize the declared type if it's a class name.
  void _initializeType() {
    final typeDef = interpreter.curNamespace
        .fetch(_declType!.typeName, from: interpreter.curNamespace.fullName);
    if (typeDef is HTClass) {
      _declType = HTInstanceType.fromClass(typeDef,
          typeArgs: _declType!.typeArgs, isNullable: _declType!.isNullable);
    } else {
      // typeDef is a function type
      _declType = typeDef;
    }

    _isTypeInitialized = true;
  }

  /// Initialize this variable with its declared initializer bytecode
  @override
  void initialize() {
    if (isInitialized) return;

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleUniqueKey: moduleUniqueKey,
            ip: definitionIp!,
            namespace: closure,
            line: definitionLine,
            column: definitionColumn);

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
  void assign(T? value) {
    if (_declType != null) {
      if (!_isTypeInitialized) {
        _initializeType();
      }

      final encapsulation = interpreter.encapsulate(value);
      final valueType = encapsulation.rtType;
      if (valueType.isNotA(_declType!)) {
        throw HTError.typeCheck(id, valueType.toString(), _declType.toString());
      }
    } else {
      if ((_declType == null) && typeInferrence && (value != null)) {
        _declType = interpreter.encapsulate(value).rtType;
        _isTypeInitialized = true;
      }
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
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          getter: getter,
          setter: setter,
          typeInferrence: typeInferrence,
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
      int? definitionLine,
      int? definitionColumn,
      bool isOptional = false,
      bool isNamed = false,
      bool isVariadic = false})
      : super(id, interpreter, moduleUniqueKey,
            value: value,
            declType: declType,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn,
            typeInferrence: false,
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
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: paramType.isOptional,
        isNamed: paramType.isNamed,
        isVariadic: paramType.isVariadic);
  }
}
