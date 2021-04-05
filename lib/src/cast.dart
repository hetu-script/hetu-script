import 'object.dart';
import 'interpreter.dart';
import 'class.dart';
import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'instance.dart';

/// The implementation of a certain type cast of a object
class HTCast with HTObject, InterpreterRef {
  late final _typeids = <HTTypeId>[];

  @override
  HTTypeId get typeid => _typeids.first;

  final HTClass klass;

  late final HTInstance object;

  @override
  String toString() => object.toString();

  HTCast(HTObject object, this.klass, Interpreter interpreter,
      {List<HTTypeId> typeArgs = const []}) {
    this.interpreter = interpreter;

    HTClass? curSuper = klass;
    while (curSuper != null) {
      // TODO: 父类没有type param怎么处理？
      final superTypeId = HTTypeId(curSuper.id);
      _typeids.add(superTypeId);
      curSuper = curSuper.superClass;
    }

    if (object.isNotA(typeid)) {
      throw HTErrorTypeCast(object.toString(), typeid.toString());
    }

    if (object is HTInstance) {
      this.object = object;
    } else if (object is HTCast) {
      this.object = object.object;
    } else {
      throw HTErrorCastee(interpreter.curSymbol!);
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      object.memberGet(varName, from: from, classId: klass.id);

  @override
  void memberSet(String varName, dynamic value,
          {String from = HTLexicon.global}) =>
      object.memberSet(varName, value, from: from, classId: klass.id);

  @override
  bool isA(HTTypeId otherTypeId) {
    if (otherTypeId == HTTypeId.ANY) {
      return true;
    } else {
      for (final superTypeId in _typeids) {
        if (superTypeId == otherTypeId) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is HTInstance) {
      return object == other;
    } else {
      return hashCode == other.hashCode;
    }
  }
}
