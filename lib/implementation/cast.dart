import 'object.dart';
import 'interpreter.dart';
import 'class.dart';
import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'instance.dart';

/// The implementation of a certain type cast of a object
class HTCast with HTObject, InterpreterRef {
  @override
  late final HTObjectType objectType;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTObject object, this.klass, Interpreter interpreter,
      {List<HTType> typeArgs = const []}) {
    this.interpreter = interpreter;

    final extended = <HTType>[];

    HTClass? curSuper = klass;
    var superClassType = HTType(klass.id, typeArgs: typeArgs);
    while (curSuper != null) {
      extended.add(superClassType);
      curSuper = curSuper.superClass;
      if (curSuper?.extendedType != null) {
        extended.add(curSuper!.extendedType!);
      }
    }

    objectType = HTObjectType(klass.id, typeArgs: typeArgs, extended: extended);

    if (object.objectType.isNotA(objectType)) {
      throw HTError.typeCast(object.toString(), objectType.toString());
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
