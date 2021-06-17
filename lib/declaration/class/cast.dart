import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../object.dart';
import '../../interpreter/interpreter.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import 'class.dart';
import 'instance.dart';

/// The implementation of a certain type cast of a object
class HTCast with HTObject, HetuRef {
  @override
  final HTNominalType valueType;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTObject object, this.klass, Hetu interpreter,
      {List<HTType> typeArgs = const []})
      : valueType = HTNominalType(klass, typeArgs: typeArgs) {
    this.interpreter = interpreter;
    // final extended = <HTType>[];

    // HTClass? curSuper = klass;
    // var superClassType = HTType(klass.id, typeArgs: typeArgs);
    // while (curSuper != null) {
    // extended.add(superClassType);
    // curSuper = curSuper.superClass;
    // if (curSuper?.extendedType != null) {
    //   extended.add(curSuper!.extendedType!);
    // }
    // }

    if (object.valueType.isNotA(valueType)) {
      throw HTError.typeCast(object.toString(), valueType.toString());
    }

    if (object is HTInstance) {
      this.object = object;
    } else if (object is HTCast) {
      this.object = object.object;
    } else {
      throw HTError.castee(interpreter.curSymbol!);
    }
  }

  @override
  dynamic memberGet(String varName,
          {String from = SemanticNames.global, bool error = true}) =>
      object.memberGet(varName, from: from, classId: klass.id);

  @override
  void memberSet(String varName, dynamic varValue,
          {String from = SemanticNames.global, bool error = true}) =>
      object.memberSet(varName, varValue, from: from, classId: klass.id);
}
