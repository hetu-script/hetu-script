import 'vm.dart';
import '../variable.dart';
import '../type.dart';
import '../errors.dart';

/// Bytecode implementation of [HTVariable].
class HTBytecodeVariable extends HTVariable with HetuRef {
  /// The module this variable declared in.
  final String moduleUniqueKey;

  /// Whether this variable have [HTTypeId].
  final bool isDynamic;

  /// Whether this variable is immutable.
  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTTypeId? _declType;

  /// The [HTTypeId] of this variable, will be used to
  /// determine wether an assignment is legal.
  HTTypeId? get declType => _declType;

  /// The instructor pointer of the initializer's bytecode.
  int? initializerIp;

  /// Create a standard [HTBytecodeVariable].
  ///
  /// A [HTVariable] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be used within a script.
  HTBytecodeVariable(String id, Hetu interpreter, this.moduleUniqueKey,
      {dynamic value,
      HTTypeId? declType,
      this.initializerIp,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            value: value, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember, isStatic: isStatic) {
    this.interpreter = interpreter;
    if (initializerIp == null && declType == null) {
      _declType = HTTypeId.ANY;
    } else {
      _declType = declType;
    }
  }

  /// Initialize this variable with its declared initializer bytecode
  @override
  void initialize() {
    if (isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(moduleUniqueKey: moduleUniqueKey, ip: initializerIp!, namespace: closure);
        assign(initVal);
        _isInitializing = false;
      } else {
        throw HTErrorCircleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  /// Assign a new value to this variable,
  /// will perform [HTTypeId] check during this process.
  @override
  void assign(dynamic value) {
    if (_declType != null) {
      final encapsulation = interpreter.encapsulate(value);
      if (encapsulation.isNotA(_declType!)) {
        final valType = interpreter.encapsulate(value).typeid;
        throw HTErrorTypeCheck(id, valType.toString(), _declType.toString());
      }
    } else if (!isDynamic && value != null) {
      _declType = interpreter.encapsulate(value).typeid;
    }

    super.assign(value);
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  @override
  HTBytecodeVariable clone() => HTBytecodeVariable(id, interpreter, moduleUniqueKey,
      value: value,
      declType: declType,
      initializerIp: initializerIp,
      getter: getter,
      setter: setter,
      isDynamic: isDynamic,
      isExtern: isExtern,
      isImmutable: isImmutable,
      isMember: isMember,
      isStatic: isStatic);
}

/// An implementation of [HTVariable] for function parameter declaration.
class HTBytesParameter extends HTBytecodeVariable {
  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a named parameter.
  final bool isNamed;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  /// Create a standard [HTBytesParameter].
  HTBytesParameter(String id, Hetu interpreter, String module,
      {dynamic value,
      HTTypeId? declType,
      int? initializerIp,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter, module,
            value: value, declType: declType, initializerIp: initializerIp, isImmutable: true);

  @override
  HTBytesParameter clone() {
    return HTBytesParameter(id, interpreter, moduleUniqueKey,
        value: value,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
