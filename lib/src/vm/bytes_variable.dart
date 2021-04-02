import 'vm.dart';
import '../variable.dart';
import '../type.dart';
import '../errors.dart';

class HTBytesVariable extends HTVariable with HetuRef {
  final String module;

  final bool isDynamic;

  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTTypeId? _declType;
  HTTypeId? get declType => _declType;

  int? initializerIp;

  HTBytesVariable(String id, Hetu interpreter, this.module,
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

  @override
  void initialize() {
    if (isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(moduleName: module, ip: initializerIp!, namespace: closure);
        assign(initVal);
        _isInitializing = false;
      } else {
        throw HTErrorCircleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

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

  @override
  HTBytesVariable clone() => HTBytesVariable(id, interpreter, module,
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

class HTBytesParameter extends HTBytesVariable {
  final bool isOptional;
  final bool isNamed;
  final bool isVariadic;

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
    return HTBytesParameter(id, interpreter, module,
        value: value,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
