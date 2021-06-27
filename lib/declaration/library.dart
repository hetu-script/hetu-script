import '../grammar/semantic.dart';
import 'namespace.dart';

class HTLibrary extends HTNamespace {
  @override
  String toString() => '${SemanticNames.library} $id';

  @override
  final String id;

  @override
  // to override the type of this filed in super type,
  // must write the type on the left
  final Map<String, HTNamespace> declarations = {};

  HTLibrary(this.id) : super(id: id);
}
