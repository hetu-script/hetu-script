import '../common/source.dart';
import 'ast.dart';

class HTAstSource extends HTSource {
  /// The bytecode, stores as uint8 list
  late final Iterable<AstNode> nodes;

  String content;

  /// Create a ast module
  HTAstSource(String fullName, this.nodes, this.content) : super(fullName);
}

class HTAstCompilation implements HTCompilation {
  final _modules = <String, HTAstSource>{};

  @override
  Iterable<String> get keys => _modules.keys;

  @override
  Iterable<HTAstSource> get sources => _modules.values;

  @override
  bool contains(String fullName) => _modules.containsKey(fullName);

  @override
  HTAstSource fetch(String fullName) {
    if (_modules.containsKey(fullName)) {
      return _modules[fullName]!;
    } else {
      throw 'Unknown source: $fullName';
    }
  }

  void add(HTAstSource source) => _modules[source.fullName] = source;

  void addAll(HTAstCompilation other) {
    _modules.addAll(other._modules);
  }
}
