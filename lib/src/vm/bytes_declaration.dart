import '../declaration.dart';
import '../type.dart';
import 'vm.dart';
import '../errors.dart';

class HTBytesDecl extends HTDeclaration with VMRef {
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
      bool typeInference = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            value: value, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember, isStatic: isStatic) {
    this.interpreter = interpreter;
    var valType = interpreter.typeof(value);
    if (declType == null) {
      if ((typeInference) && (value != null)) {
        this.declType = valType;
      } else {
        this.declType = HTTypeId.ANY;
      }
    } else {
      if (valType.isA(declType)) {
        this.declType = declType;
      } else {
        throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
      }
    }
  }

  @override
  void initialize() {
    if (_isInitialized) return;

    if (initializerIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        value = interpreter.execute(ip: initializerIp!);
        _isInitialized = true;
      } else {
        throw HTErrorCircleInit(id);
      }
    }

    throw HTErrorInitialize();
  }

  @override
  HTBytesDecl clone() => HTBytesDecl(id, interpreter,
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
      {HTTypeId? declType,
      int? initializerIp,
      bool typeInference = false,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter, declType: declType, initializerIp: initializerIp, typeInference: typeInference) {}

  @override
  HTBytesParamDecl clone() {
    return HTBytesParamDecl(id, interpreter,
        declType: declType,
        initializerIp: initializerIp,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}
