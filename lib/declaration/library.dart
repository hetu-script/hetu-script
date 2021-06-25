import 'namespace.dart';

class HTLibrary extends HTNamespace {
  @override
  final String id;

  @override
  final Map<String, HTNamespace> declarations = {};

  HTLibrary(this.id) : super(id: id);
}
