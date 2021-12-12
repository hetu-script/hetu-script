import '../../grammar/semantic.dart';
import 'namespace.dart';

/// [HTLibrary] is the semantic entity of a program or package
/// it contains all object and code interpreter generated.
class HTLibrary extends HTNamespace {
  @override
  String toString() => '${SemanticNames.library} $id';

  final String _id;

  @override
  String get id => _id;

  final Map<String, HTNamespace> _namespaces;

  @override
  Map<String, HTNamespace> get declarations => _namespaces;

  HTLibrary(this._id, {Map<String, HTNamespace>? declarations})
      : _namespaces = declarations ?? <String, HTNamespace>{},
        super(id: _id);
}
