import '../../declaration/declaration.dart';
import '../../binding/external_class.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../entity.dart';
import '../../value/namespace/namespace.dart';
import '../../source/source.dart';

class HTExternalEnum extends HTDeclaration with HTEntity, InterpreterRef {
  HTExternalClass? externalClass;

  bool get isNested => classId != null;

  HTExternalEnum(
    String id,
    HTAbstractInterpreter interpreter, {
    String? classId,
    HTNamespace? closure,
    HTSource? source,
  }) : super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: true) {
    this.interpreter = interpreter;
  }

  @override
  dynamic memberGet(String varName, {String? from}) {
    final item = externalClass!.memberGet(varName);
    return item;
  }

  @override
  void resolve() {
    super.resolve();
    externalClass = interpreter.fetchExternalClass(id!);
  }

  @override
  HTExternalEnum clone() => HTExternalEnum(id!, interpreter);
}
