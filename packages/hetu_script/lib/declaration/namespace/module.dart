import '../../grammar/semantic.dart';
import 'namespace.dart';

/// [HTModule] is the semantic entity of a program or package
/// it contains all object and code interpreter generated.
class HTModule extends HTNamespace {
  @override
  String toString() => '${Semantic.module} $id';

  final String _id;

  @override
  String get id => _id;

  final Map<String, HTNamespace> _namespaces;

  @override
  Map<String, HTNamespace> get declarations => _namespaces;

  final importedExpressionModules = <String, dynamic>{};

  HTModule(this._id, {Map<String, HTNamespace>? declarations})
      : _namespaces = declarations ?? <String, HTNamespace>{},
        super(id: _id);
}
