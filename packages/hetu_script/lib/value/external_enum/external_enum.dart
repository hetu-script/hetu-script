import '../../declaration/declaration.dart';
import '../../external/external_class.dart';
import '../../interpreter/interpreter.dart';
import '../entity.dart';
// import '../../value/namespace/namespace.dart';
// import '../../source/source.dart';

class HTExternalEnum extends HTDeclaration with HTEntity, InterpreterRef {
  HTExternalClass? externalClass;

  bool get isNested => classId != null;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTExternalEnum(
    HTInterpreter interpreter, {
    required super.id,
    super.classId,
    super.closure,
    super.source,
  }) : super(isExternal: true) {
    this.interpreter = interpreter;
  }

  @override
  dynamic memberGet(String varName, {String? from}) {
    final item = externalClass!.memberGet(varName);
    return item;
  }

  @override
  void resolve() {
    if (_isResolved) return;
    super.resolve();
    externalClass = interpreter.fetchExternalClass(id!);
    _isResolved = true;
  }

  @override
  HTExternalEnum clone() => HTExternalEnum(interpreter, id: id!);
}
