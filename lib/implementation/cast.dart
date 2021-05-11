import '../common/errors.dart';
import 'object.dart';
import 'interpreter.dart';
import 'class.dart';
import 'type.dart';
import 'lexicon.dart';
import 'instance.dart';

/// The implementation of a certain type cast of a object
class HTCast with HTObject, InterpreterRef {
  @override
  late final HTNominalType valueType;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTObject object, this.klass, Interpreter interpreter,
      {List<HTDeclarationType> typeArgs = const []}) {
    this.interpreter = interpreter;

    // final extended = <HTType>[];

    // HTClass? curSuper = klass;
    // var superClassType = HTDeclarationType(klass.id, typeArgs: typeArgs);
    // while (curSuper != null) {
    // extended.add(superClassType);
    // curSuper = curSuper.superClass;
    // if (curSuper?.extendedType != null) {
    //   extended.add(curSuper!.extendedType!);
    // }
    // }

    valueType = HTNominalType(klass,
        typeArgs: typeArgs.map((type) => type.resolve(interpreter)));

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
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      object.memberGet(varName, from: from, classId: klass.id);

  @override
  void memberSet(String varName, dynamic varValue,
          {String from = HTLexicon.global}) =>
      object.memberSet(varName, varValue, from: from, classId: klass.id);
}
