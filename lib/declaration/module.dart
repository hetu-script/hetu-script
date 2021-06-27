import '../grammar/semantic.dart';
import '../source/source.dart';
import 'namespace.dart';

class HTModule extends HTNamespace {
  @override
  String toString() => '${SemanticNames.module} $id';

  @override
  final String id;

  HTModule(this.id, {HTSource? source}) : super(source: source);
}
