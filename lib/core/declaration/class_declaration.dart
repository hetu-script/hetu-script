import '../../type/type.dart';
import 'variable_declaration.dart';
import '../abstract_interpreter.dart';

class ClassDeclaration extends VariableDeclaration {
  /// The type parameters of the class.
  final Iterable<HTType> genericParameters;

  HTType? _superType;

  HTType? get superType => _superType;

  /// Mixined class of this class.
  /// Those mixined class can not have any constructors.
  final Iterable<HTType> withTypes;

  /// Implemented classes of this class.
  /// Implements only inherits methods declaration,
  /// and the child must re-define all implements methods,
  /// and the re-definition must be of the same function signature.
  final Iterable<HTType> implementsTypes;

  final bool isAbstract;

  ClassDeclaration(String id, String moduleFullName, String libraryName,
      {this.genericParameters = const [],
      HTType? superType,
      this.withTypes = const [],
      this.implementsTypes = const [],
      String? classId,
      bool isExternal = false,
      this.isAbstract = false})
      : super(id, moduleFullName, libraryName,
            classId: classId, isExternal: isExternal) {
    _superType = superType;
  }

  @override
  void resolve(AbstractInterpreter interpreter) {
    super.resolve(interpreter);

    if ((_superType != null) && !_superType!.isResolved) {
      _superType = _superType!.resolve(interpreter);
    }
  }
}
