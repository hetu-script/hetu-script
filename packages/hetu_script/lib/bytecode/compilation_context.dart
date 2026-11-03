import '../ast/ast.dart';
import '../optimization/optimization_result.dart';
import 'synthetic_node.dart';

class HTForLowering {
  final VarDecl? initializer;
  final ASTNode condition;
  final ASTNode? increment;
  final BlockStmt loop;
  final Map<String, String> markedSymbols;

  HTForLowering({
    required this.initializer,
    required this.condition,
    required this.increment,
    required this.loop,
    required this.markedSymbols,
  });
}

class HTForRangeLowering {
  final VarDecl iterator;
  final CallExpr condition;
  final BlockStmt loop;

  HTForRangeLowering({
    required this.iterator,
    required this.condition,
    required this.loop,
  });
}

class HTCompilationContext {
  final HTOptimizationResult optimization;
  final HTSyntheticNodeTable syntheticNodes = HTSyntheticNodeTable();
  final Map<ASTNode, HTResolvedVariable> syntheticDeclarations =
      Map<ASTNode, HTResolvedVariable>.identity();
  final Map<ASTNode, HTResolvedVariable> syntheticReferences =
      Map<ASTNode, HTResolvedVariable>.identity();
  final Map<ASTNode, ASTNode> _expressions = Map<ASTNode, ASTNode>.identity();
  final Map<ForExpr, HTForLowering> _forLoops =
      Map<ForExpr, HTForLowering>.identity();
  final Map<ForRangeExpr, HTForRangeLowering> _forRangeLoops =
      Map<ForRangeExpr, HTForRangeLowering>.identity();

  var _iteratorIndex = 0;

  HTCompilationContext(this.optimization);

  int get iteratorCount => _iteratorIndex;

  String nextIteratorId() => '__iter${_iteratorIndex++}';

  ASTNode? loweredExpression(ASTNode node) => _expressions[node];

  HTForLowering? forLoop(ForExpr node) => _forLoops[node];

  HTForRangeLowering? forRangeLoop(ForRangeExpr node) => _forRangeLoops[node];

  void recordExpression(ASTNode origin, ASTNode lowered) {
    _expressions[origin] = lowered;
    syntheticNodes.record(lowered, origin);
  }

  void recordForLoop(ForExpr origin, HTForLowering lowered) {
    _forLoops[origin] = lowered;
  }

  void recordForRangeLoop(ForRangeExpr origin, HTForRangeLowering lowered) {
    _forRangeLoops[origin] = lowered;
  }

  T recordSynthetic<T extends ASTNode>(T node, ASTNode origin) {
    syntheticNodes.record(node, origin);
    return node;
  }

  IdentifierExpr declarationIdentifier(
    String id,
    HTResolvedVariable variable,
    ASTNode origin,
  ) {
    final expression = IdentifierExpr(
      id,
      role: HTIdentifierRole.synthetic,
      source: origin.source,
      line: origin.line,
      column: origin.column,
      offset: origin.offset,
      length: origin.length,
    );
    syntheticDeclarations[expression] = variable;
    return recordSynthetic(expression, origin);
  }

  IdentifierExpr referenceIdentifier(
    String id,
    HTResolvedVariable variable,
    ASTNode origin,
  ) {
    final expression = IdentifierExpr(
      id,
      role: HTIdentifierRole.synthetic,
      source: origin.source,
      line: origin.line,
      column: origin.column,
      offset: origin.offset,
      length: origin.length,
    );
    syntheticReferences[expression] = variable;
    return recordSynthetic(expression, origin);
  }
}
