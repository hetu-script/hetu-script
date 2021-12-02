import '../../declaration/declaration.dart';
import '../../binding/external_class.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../entity.dart';
import '../../declaration/namespace/namespace.dart';
import '../../source/source.dart';

class ExternalEnum extends HTDeclaration with HTEntity, InterpreterRef {
  @override
  final String id;

  HTExternalClass? externalClass;

  bool get isNested => classId != null;

  ExternalEnum(
    this.id,
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
  dynamic memberGet(String varName) {
    final item = externalClass!.memberGet(varName);
    return item;
  }

  @override
  void resolve() {
    super.resolve();
    externalClass = interpreter.fetchExternalClass(id);
  }

  @override
  ExternalEnum clone() => ExternalEnum(id, interpreter);
}
