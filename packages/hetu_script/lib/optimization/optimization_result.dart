import '../../ast/ast.dart';

enum HTResolvedStorage {
  localSlot,
  capturedCell,
  moduleDeclaration,
  dynamic,
}

enum HTResolvedScopeKind {
  module,
  function,
  block,
  dynamic,
}

class HTResolvedScope {
  final HTResolvedScopeKind kind;
  final HTResolvedScope? parent;
  final ASTNode? declaration;
  final Map<String, List<HTResolvedVariable>> _declarations = {};

  HTResolvedScope(this.kind, this.parent, this.declaration);

  HTResolvedScope? get function =>
      kind == HTResolvedScopeKind.function ? this : parent?.function;

  Iterable<HTResolvedVariable> get variables =>
      _declarations.values.expand((variables) => variables);

  HTResolvedVariable? lookup(String name) => _declarations[name]?.lastOrNull;

  void add(HTResolvedVariable variable) {
    _declarations.putIfAbsent(variable.name, () => []).add(variable);
  }
}

class HTResolvedVariable {
  final ASTNode declaration;
  final String name;
  final HTResolvedScope scope;
  final int? slot;
  final bool isSynthetic;
  HTResolvedStorage storage;

  HTResolvedVariable({
    required this.declaration,
    required this.name,
    required this.scope,
    required this.storage,
    required this.slot,
    this.isSynthetic = false,
  });
}

class HTResolvedReference {
  final HTResolvedVariable variable;

  HTResolvedReference(this.variable);

  HTResolvedStorage get storage => variable.storage;
}

class HTFunctionOptimization {
  final HTResolvedScope scope;
  final Map<int, String> slotNames = {};
  final List<HTResolvedVariable> capturedVariables = [];
  final List<HTResolvedVariable> upvalues = [];
  int localSlotCount = 0;

  HTFunctionOptimization(this.scope);
}

class HTOptimizationResult {
  final Map<ASTNode, HTResolvedReference> references =
      Map<ASTNode, HTResolvedReference>.identity();
  final Map<ASTNode, HTFunctionOptimization> functions =
      Map<ASTNode, HTFunctionOptimization>.identity();
  final Map<ASTNode, HTResolvedVariable> declarations =
      Map<ASTNode, HTResolvedVariable>.identity();
  final Map<ASTNode, HTResolvedScope> scopes =
      Map<ASTNode, HTResolvedScope>.identity();
  final Map<ASTSource, HTResolvedScope> sourceScopes =
      Map<ASTSource, HTResolvedScope>.identity();
  final Map<ASTNode, List<HTResolvedVariable>> loopBindings =
      Map<ASTNode, List<HTResolvedVariable>>.identity();
  final Set<ASTNode> dynamicOperations = Set<ASTNode>.identity();
  final List<HTResolvedVariable> variables = [];
}
