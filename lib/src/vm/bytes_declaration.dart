import 'dart:typed_data';

import '../declaration.dart';
import '../type.dart';
import 'vm.dart';
import '../errors.dart';

class HTBytesDeclaration extends HTDeclaration with VMRef {
  @override
  late final HTTypeId? declType;

  Uint8List? initializer;

  HTBytesDeclaration(String id, HTVM interpreter,
      {dynamic value,
      HTTypeId? declType,
      this.initializer,
      Function? getter,
      Function? setter,
      bool typeInference = false,
      bool isExtern = false,
      bool isNullable = false,
      bool isImmutable = false})
      : super(
          id,
          value: value,
          getter: getter,
          setter: setter,
          isExtern: isExtern,
          isNullable: isNullable,
          isImmutable: isImmutable,
        ) {
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
  HTBytesDeclaration clone() {
    return HTBytesDeclaration(id, interpreter,
        initializer: initializer,
        getter: getter,
        setter: setter,
        declType: declType,
        isExtern: isExtern,
        isNullable: isNullable,
        isImmutable: isImmutable);
  }

  @override
  void initialize() {
    // value = interpreter.eval(initializer!);
  }
}
