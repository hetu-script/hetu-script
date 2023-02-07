import '../../type/type.dart';
import '../declaration.dart';

/// A interface shared by parameter declaration and parameter
/// this is to fix mulitple inheritance issue.
abstract class HTAbstractParameter implements HTDeclaration {
  bool get isVariadic;

  bool get isOptional;

  bool get isNamed;

  bool get isInitialization;

  @override
  HTType? get declType;

  @override
  void resolve();

  @override
  HTAbstractParameter clone();

  void initialize();
}
