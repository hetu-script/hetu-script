import '../source/source.dart';
import '../core/const_table.dart';
import 'ast/ast.dart';

class HTAstModule extends HTModule {
  /// The bytecode, stores as uint8 list
  final Iterable<AstNode> nodes;

  /// Create a ast module
  HTAstModule(
      String fullName, String content, this.nodes, ConstTable constTable)
      : super(fullName, content, constTable);
}

class HTAstCompilation extends HTCompilation {
  final _symbols = <String, AstNode>{};

  @override
  Iterable<String> get symbols => _symbols.keys;

  @override
  bool containsSymbol(String id) => _symbols.containsKey(id);

  final _modules = <String, HTAstModule>{};

  @override
  Iterable<String> get moduleKeys => _modules.keys;

  @override
  Iterable<HTAstModule> get modules => _modules.values;

  @override
  bool containsModule(String fullName) => _modules.containsKey(fullName);

  @override
  HTAstModule getModule(String fullName) {
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
