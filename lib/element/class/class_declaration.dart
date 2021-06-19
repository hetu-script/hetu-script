import '../../type/type.dart';
import '../namespace.dart';

class HTClassDeclaration extends HTNamespace {
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

  final bool isNested;

  final bool isAbstract;

  HTClassDeclaration(String id, String moduleFullName, String libraryName,
      {String? classId,
      this.genericParameters = const [],
      HTType? superType,
      this.withTypes = const [],
      this.implementsTypes = const [],
      this.isNested = false,
      bool isExternal = false,
      this.isAbstract = false,
      HTNamespace? closure})
      : super(moduleFullName, libraryName,
            id: id, classId: classId, closure: closure) {
    _superType = superType;
  }

  @override
  void resolve() {
    super.resolve();

    if ((closure != null) && (_superType != null) && !_superType!.isResolved) {
      _superType = _superType!.resolve(closure!);
    }
  }

  @override
  HTClassDeclaration clone() =>
      HTClassDeclaration(id, moduleFullName, libraryName,
          classId: classId,
          genericParameters: genericParameters,
          superType: superType,
          withTypes: withTypes,
          implementsTypes: implementsTypes,
          isNested: isNested,
          isExternal: isExternal,
          isAbstract: isAbstract,
          closure: closure);
}
