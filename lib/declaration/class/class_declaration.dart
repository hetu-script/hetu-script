import '../type/type.dart';
import '../declaration.dart';
import '../namespace.dart';

class ClassDeclaration extends Declaration {
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
      {String? classId,
      this.genericParameters = const [],
      HTType? superType,
      this.withTypes = const [],
      this.implementsTypes = const [],
      bool isExternal = false,
      this.isAbstract = false})
      : super(id, moduleFullName, libraryName,
            classId: classId, isExternal: isExternal) {
    _superType = superType;
  }

  @override
  void resolve(HTNamespace namespace) {
    super.resolve(namespace);

    if ((_superType != null) && !_superType!.isResolved) {
      _superType = _superType!.resolve(namespace);
    }
  }

  @override
  ClassDeclaration clone() => ClassDeclaration(id, moduleFullName, libraryName,
      classId: classId,
      genericParameters: genericParameters,
      superType: superType,
      withTypes: withTypes,
      implementsTypes: implementsTypes,
      isExternal: isExternal,
      isAbstract: isAbstract);
}
