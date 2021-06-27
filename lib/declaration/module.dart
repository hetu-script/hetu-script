import '../grammar/semantic.dart';
import '../source/source.dart';
import 'namespace.dart';

class HTModule extends HTNamespace {
  @override
  String toString() => '${SemanticNames.module} $id';

  @override
  String get id => source.fullName;

  @override
  final HTSource source;

  HTModule(this.source) : super(source: source);
}
