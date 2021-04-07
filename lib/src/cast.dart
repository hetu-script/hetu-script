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
  late final HTInstanceType rtType;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTObject object, this.klass, Interpreter interpreter,
      {List<HTType> typeArgs = const []}) {
    this.interpreter = interpreter;

    final extended = <HTType>[];

    HTClass? curSuper = klass;
    while (curSuper != null) {
      // TODO: 父类没有type param怎么处理？
      final superType = HTType(curSuper.id);
      extended.add(superType);
      curSuper = curSuper.superClass;
    }

    rtType = HTInstanceType(klass.id, typeArgs: typeArgs, extended: extended);

    if (object.rtType.isNotA(rtType)) {
      throw HTError.typeCast(object.toString(), rtType.toString());
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
  void memberSet(String varName, dynamic value,
          {String from = HTLexicon.global}) =>
      object.memberSet(varName, value, from: from, classId: klass.id);
}
