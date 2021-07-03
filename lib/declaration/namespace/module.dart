import '../../grammar/semantic.dart';
import '../../source/source.dart';
import 'namespace.dart';

/// Module is the semantic entity of a single file,
/// it contains all object and code interpreter generated.
class HTModule extends HTNamespace {
  @override
  String toString() => '${SemanticNames.module} $id';

  @override
  final String id;

  HTModule(this.id, {HTSource? source}) : super(source: source);
}
