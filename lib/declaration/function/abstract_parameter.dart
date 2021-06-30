import '../../type/type.dart';
import '../declaration.dart';

abstract class HTAbstractParameter implements HTDeclaration {
  @override
  String get id;

  bool get isOptional;

  bool get isNamed;

  bool get isVariadic;

  HTType? get declType;

  @override
  void resolve();

  @override
  HTAbstractParameter clone();
}
