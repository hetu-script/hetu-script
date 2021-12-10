import '../../grammar/semantic.dart';
import 'namespace.dart';

/// [HTLibrary] is the semantic entity of a program or package
/// it contains all object and code interpreter generated.
class HTLibrary extends HTNamespace {
  @override
  String toString() => '${SemanticNames.library} $id';

  @override
  final String id;

  @override
  final Map<String, HTNamespace> declarations;

  HTLibrary(this.id, {Map<String, HTNamespace>? declarations})
      : declarations = declarations ?? <String, HTNamespace>{},
        super(id: id);
}
