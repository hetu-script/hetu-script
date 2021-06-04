import 'package:path/path.dart' as path;

import '../source/source.dart';
import '../core/const_table.dart';
import 'ast.dart';

class HTAstModule extends HTSource {
  final Uri uri;

  late final ConstTable constTable;

  String get name => path.basename(fullName);

  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  HTAstModule(String fullName, String content, this.nodes,
      [ConstTable? constTable])
      : uri = Uri(path: fullName),
        constTable = constTable ?? ConstTable(),
        super(fullName, content);
}

class HTAstCompilation {
  final _symbols = <String, AstNode>{};

  Iterable<String> get symbols => _symbols.keys;

  bool containsSymbol(String id) => _symbols.containsKey(id);

  final _modules = <String, HTAstModule>{};

  Iterable<String> get moduleKeys => _modules.keys;

  Iterable<HTAstModule> get modules => _modules.values;

  bool containsModule(String fullName) => _modules.containsKey(fullName);

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
