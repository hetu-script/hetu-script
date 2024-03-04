import '../../declaration/declaration.dart';
import '../../external/external_class.dart';
import '../../interpreter/interpreter.dart';
import '../object.dart';
// import '../../value/namespace/namespace.dart';
// import '../../source/source.dart';

class HTExternalEnum extends HTDeclaration with HTObject, InterpreterRef {
  HTExternalClass? externalClass;

  bool get isNested => classId != null;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTExternalEnum(
    HTInterpreter interpreter, {
    required String id,
    super.documentation,
  }) : super(
          id: id,
          isExternal: true,
          isTopLevel: true,
        ) {
    this.interpreter = interpreter;
  }

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    final item = externalClass!
        .memberGet(id, from: from, ignoreUndefined: ignoreUndefined);
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
