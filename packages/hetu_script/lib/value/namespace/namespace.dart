import '../../declaration/namespace/declaration_namespace.dart';
import '../../source/source.dart';

/// A namespace that will return the actual value of the declaration.
class HTNamespace extends HTDeclarationNamespace {
  final HTNamespace? _closure;

  @override
  HTNamespace? get closure => _closure;

  HTNamespace(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isTopLevel = false})
      : _closure = closure,
        super(
          id: id,
          classId: classId,
          closure: closure,
          source: source,
        );
}
