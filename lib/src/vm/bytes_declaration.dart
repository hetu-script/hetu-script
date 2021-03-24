import '../declaration.dart';
import '../type.dart';
import 'vm.dart';
import '../errors.dart';

class HTBytesDecl extends HTDeclaration with VMRef {
  final bool isDynamic;

  @override
  final bool isImmutable;

  var _isInitializing = false;
  var _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  late final HTTypeId? declType;

  int? initializerIp;

  HTBytesDecl(String id, HTVM interpreter,
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

    if (value != null) _isInitialized = true;
  }

  @override
  void initialize() {
    if (_isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(ip: initializerIp!);
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
    if (isImmutable && _isInitialized) {
      throw HTErrorImmutable(id);
    }

    var valType = interpreter.typeof(value);
    if (declType == null) {
      if (!isDynamic && value != null) {
        declType = valType;
      } else {
        declType = HTTypeId.ANY;
      }
    } else if (valType.isNotA(declType)) {
      throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
    }
    this.value = value;
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  @override
  HTBytesDecl clone() => HTBytesDecl(id, interpreter,
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

  HTBytesParamDecl(String id, HTVM interpreter,
      {dynamic value,
      HTTypeId? declType,
      int? initializerIp,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter, value: value, declType: declType, initializerIp: initializerIp, isImmutable: true);

  @override
  HTBytesParamDecl clone() {
    return HTBytesParamDecl(id, interpreter,
        value: value,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
