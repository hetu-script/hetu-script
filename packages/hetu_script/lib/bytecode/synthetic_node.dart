import '../ast/ast.dart';

class HTSyntheticNodeTable {
  final Map<ASTNode, ASTNode> _origins = Map<ASTNode, ASTNode>.identity();

  void record(ASTNode node, ASTNode origin) {
    if (!identical(node, origin)) {
      _origins[node] = origin;
    }
  }

  ASTNode? originOf(ASTNode node) => _origins[node];

  Iterable<ASTNode> get nodes => _origins.keys;
}
