import '../declaration.dart';
import '../type.dart';
import 'vm.dart';
import '../errors.dart';

class HTBytesDecl extends HTDeclaration with VMRef {
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
      bool isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            value: value,
            getter: getter,
            setter: setter,
            isExtern: isExtern,
            isImmutable: isImmutable,
            isMember: isMember,
            isStatic: isStatic) {
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
  HTBytesDecl clone() {
    return HTBytesDecl(id, interpreter,
        initializerIp: initializerIp,
        getter: getter,
        setter: setter,
        declType: declType,
        isExtern: isExtern,
        isImmutable: isImmutable);
  }

  @override
  void initialize() {
    if (initializerIp != null) {
      value = interpreter.execute(ip: initializerIp!);
    }
  }
}

class HTBytesParamDecl extends HTDeclaration {
  final bool isOptional;
  final bool isNamed;
  final bool isVariadic;

  HTBytesParamDecl(String id,
      {HTTypeId declType = HTTypeId.ANY, this.isOptional = false, this.isNamed = false, this.isVariadic = false})
      : super(id, declType: declType) {
    // this.interpreter = interpreter;
    // var valType = interpreter.typeof(value);
    // if (valType.isA(declType) || value == null) {
    //   this.declType = declType;
    // } else {
    //   throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
    // }

    // if (value != null) {
    //   _isInitialized = true;
    // }
  }
}
