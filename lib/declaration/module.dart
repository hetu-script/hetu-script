import 'namespace.dart';
import '../source/source.dart';

class HTModule extends HTNamespace {
  @override
  String get id => source.fullName;

  @override
  final HTSource source;

  HTModule(this.source) : super(source: source);
}
