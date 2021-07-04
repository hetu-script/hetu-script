import '../../grammar/semantic.dart';
import 'namespace.dart';

/// [HTModule] is the semantic entity of a single file,
/// it contains all object and code interpreter generated.
class HTModule extends HTNamespace {
  @override
  String toString() => '${SemanticNames.module} $id';

  @override
  final String id;

  final bool isLibraryEntry;

  HTModule(this.id, {HTNamespace? closure, this.isLibraryEntry = false})
      : super(id: id, closure: closure);
}
