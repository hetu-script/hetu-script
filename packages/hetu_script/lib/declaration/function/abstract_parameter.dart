import '../../type/type.dart';
import '../declaration.dart';

abstract class HTAbstractParameter implements HTDeclaration {
  bool get isOptional;

  bool get isNamed;

  bool get isVariadic;

  HTType? get declType;

  @override
  void resolve();

  @override
  HTAbstractParameter clone();

  @override
  String toString();
}
