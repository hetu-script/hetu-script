import '../declaration.dart';
import '../type.dart';
import 'vm.dart';
import '../errors.dart';

class HTBytesDecl extends HTDeclaration with HetuRef {
  final String module;

  final bool isDynamic;

  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTTypeId? _declType;
  HTTypeId? get declType => _declType;

  int? initializerIp;

  HTBytesDecl(String id, Hetu interpreter, this.module,
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
      declType = HTTypeId.ANY;
    }
  }

  @override
  void initialize() {
    if (isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final savedModule = interpreter.curModule;
        interpreter.curModule = module;
        interpreter.curCode = interpreter.modules[module]!;
        final initVal = interpreter.execute(ip: initializerIp!);
        interpreter.curModule = savedModule;
        interpreter.curCode = interpreter.modules[savedModule]!;
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
    var valType = interpreter.typeof(value);
    if (_declType == null) {
      if (!isDynamic && value != null) {
        _declType = valType;
      } else {
        _declType = HTTypeId.ANY;
      }
    } else if (valType.isNotA(_declType!)) {
      throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
    }

    super.assign(value);
  }

  @override
  HTBytesDecl clone() => HTBytesDecl(id, interpreter, module,
      value: value,
      initializerIp: initializerIp,
      getter: getter,
      setter: setter,
      declType: declType,
      isExtern: isExtern,
      isImmutable: isImmutable);
}

class HTBytesParamDecl extends HTBytesDecl {
  final bool isOptional;
  final bool isNamed;
  final bool isVariadic;

  HTBytesParamDecl(String id, Hetu interpreter, String module,
      {dynamic value,
      HTTypeId? declType,
      int? initializerIp,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter, module,
            value: value, declType: declType, initializerIp: initializerIp, isImmutable: true);

  @override
  HTBytesParamDecl clone() {
    return HTBytesParamDecl(id, interpreter, module,
        value: value,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
