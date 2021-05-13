import '../source/source.dart';
import '../core/const_table.dart';
import 'ast/ast.dart';

class HTAstModule extends HTModule {
  /// The bytecode, stores as uint8 list
  final Iterable<AstNode> nodes;

  /// Create a ast module
  HTAstModule(String fullName, String content, this.nodes,
      [ConstTable? constTable])
      : super(fullName, content, constTable);
}

class HTAstCompilation extends HTCompilation {
  final _modules = <String, HTAstModule>{};

  @override
  Iterable<String> get keys => _modules.keys;

  @override
  Iterable<HTAstModule> get sources => _modules.values;

  @override
  bool contains(String fullName) => _modules.containsKey(fullName);

  @override
  HTAstModule fetch(String fullName) {
    if (_modules.containsKey(fullName)) {
      return _modules[fullName]!;
    } else {
      throw 'Unknown source: $fullName';
    }
  }

  void add(HTAstModule source) => _modules[source.fullName] = source;

  void addAll(HTAstCompilation other) {
    _modules.addAll(other._modules);
  }
}
