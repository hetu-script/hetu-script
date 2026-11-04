import '../ast/ast.dart';
import '../ast/visitor/recursive_ast_visitor.dart';
import '../common/function_category.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import 'optimization_result.dart';

class HTOptimizationResolver {
  final HTLexicon _lexicon;

  HTOptimizationResolver({HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTLexiconHetu();

  HTOptimizationResult resolveCompilation(ASTCompilation compilation) {
    final result = HTOptimizationResult();
    final visitor = _OptimizationVisitor(result, _lexicon);
    visitor.build(compilation);
    visitor.resolve(compilation);
    propagateDynamicScopes(result);
    return result;
  }

  HTOptimizationResult resolveSource(ASTSource source) {
    final result = HTOptimizationResult();
    final visitor = _OptimizationVisitor(result, _lexicon);
    visitor.buildSource(source);
    visitor.resolveSource(source);
    propagateDynamicScopes(result);
    return result;
  }

  void propagateDynamicScopes(HTOptimizationResult result) {
    var changed = true;
    while (changed) {
      changed = false;
      for (final optimization in result.functions.values) {
        if (optimization.localSlotCount > 65535 &&
            !optimization.requiresDynamicScope) {
          optimization.requiresDynamicScope = true;
          changed = true;
        }
        if (!optimization.requiresDynamicScope) continue;
        for (final upvalue in optimization.upvalues) {
          final owner = upvalue.scope.function;
          if (owner == null) continue;
          final ownerOptimization = result.functions[owner.declaration]!;
          if (!ownerOptimization.requiresDynamicScope) {
            ownerOptimization.requiresDynamicScope = true;
            changed = true;
          }
        }
      }
    }
  }
}

class _PendingLoopVariable {
  final ASTNode loop;
  final BlockStmt block;
  final ASTNode declaration;
  final IdentifierExpr id;
  final String name;

  _PendingLoopVariable({
    required this.loop,
    required this.block,
    required this.declaration,
    required this.id,
    required this.name,
  });
}

class _MarkedLoopSymbols {
  final HTResolvedScope scope;
  final Map<String, HTResolvedVariable> variables;

  _MarkedLoopSymbols(this.scope, this.variables);
}

class _OptimizationVisitor extends RecursiveASTVisitor<void> {
  final HTOptimizationResult result;
  final HTLexicon lexicon;
  final List<_PendingLoopVariable> pendingLoopVariables = [];
  final List<_MarkedLoopSymbols> markedLoopSymbols = [];

  bool building = true;
  HTResolvedScope currentScope =
      HTResolvedScope(HTResolvedScopeKind.module, null, null);

  _OptimizationVisitor(this.result, this.lexicon);

  void build(ASTCompilation compilation) {
    building = true;
    compilation.accept(this);
  }

  void resolve(ASTCompilation compilation) {
    building = false;
    compilation.accept(this);
  }

  void buildSource(ASTSource source) {
    building = true;
    source.accept(this);
  }

  void resolveSource(ASTSource source) {
    building = false;
    source.accept(this);
  }

  void enterScope(ASTNode node, HTResolvedScopeKind kind) {
    if (building) {
      result.scopes[node] = HTResolvedScope(kind, currentScope, node);
      if (kind == HTResolvedScopeKind.function) {
        result.functions[node] = HTFunctionOptimization(result.scopes[node]!);
      }
    }
    currentScope = result.scopes[node]!;
  }

  HTResolvedVariable declareVariable(
    ASTNode declaration,
    IdentifierExpr id, {
    String? name,
    bool isSynthetic = false,
  }) {
    final function = currentScope.function;
    final storage = switch (currentScope.kind) {
      HTResolvedScopeKind.module => HTResolvedStorage.moduleDeclaration,
      HTResolvedScopeKind.dynamic => HTResolvedStorage.dynamic,
      _ when function == null => HTResolvedStorage.dynamic,
      _ => HTResolvedStorage.localSlot,
    };
    final optimization =
        function == null || storage != HTResolvedStorage.localSlot
            ? null
            : result.functions[function.declaration]!;
    final slot = optimization?.localSlotCount;
    if (optimization != null) {
      optimization.localSlotCount++;
    }
    final variable = HTResolvedVariable(
      declaration: declaration,
      name: name ?? id.id,
      scope: currentScope,
      storage: storage,
      slot: slot,
      isSynthetic: isSynthetic,
    );
    currentScope.add(variable);
    result.variables.add(variable);
    if (!isSynthetic) {
      result.declarations[id] = variable;
    }
    if (slot != null) {
      optimization!.slotNames[slot] = variable.name;
    }
    return variable;
  }

  void addIdentity(
    List<HTResolvedVariable> variables,
    HTResolvedVariable variable,
  ) {
    if (!variables.any((item) => identical(item, variable))) {
      variables.add(variable);
    }
  }

  void requireDynamicScope() {
    final function = currentScope.function;
    if (function != null) {
      result.functions[function.declaration]!.requiresDynamicScope = true;
    }
  }

  HTResolvedVariable? lookup(String name) {
    if (markedLoopSymbols.isNotEmpty) {
      final markedVariable = markedLoopSymbols.last.variables[name];
      if (markedVariable != null) {
        return markedVariable;
      }
    }
    HTResolvedScope? scope = currentScope;
    while (scope != null) {
      final variable = scope.lookup(name);
      if (variable != null) {
        return variable;
      }
      scope = scope.parent;
    }
    return null;
  }

  void resolveSymbol(String name, ASTNode referenceNode) {
    var variable = lookup(name);
    if (variable == null) {
      requireDynamicScope();
      variable = HTResolvedVariable(
        declaration: referenceNode,
        name: name,
        scope: currentScope,
        storage: HTResolvedStorage.dynamic,
        slot: null,
      );
    } else if (variable.storage == HTResolvedStorage.localSlot ||
        variable.storage == HTResolvedStorage.capturedCell) {
      final currentFunction = currentScope.function;
      final ownerFunction = variable.scope.function;
      if (currentFunction != null &&
          ownerFunction != null &&
          !identical(currentFunction, ownerFunction)) {
        if (variable.storage == HTResolvedStorage.localSlot) {
          variable.storage = HTResolvedStorage.capturedCell;
        }
        final ownerOptimization = result.functions[ownerFunction.declaration]!;
        addIdentity(ownerOptimization.capturedVariables, variable);
        HTResolvedScope? nestedFunction = currentFunction;
        while (nestedFunction != null &&
            !identical(nestedFunction, ownerFunction)) {
          final optimization = result.functions[nestedFunction.declaration]!;
          addIdentity(optimization.upvalues, variable);
          nestedFunction = nestedFunction.parent?.function;
        }
      }
    }
    result.references[referenceNode] = HTResolvedReference(variable);
  }

  @override
  void visitCompilation(ASTCompilation node) {
    for (final source in node.values.values) {
      source.accept(this);
    }
    for (final source in node.sources.values) {
      source.accept(this);
    }
  }

  @override
  void visitSource(ASTSource node) {
    final savedScope = currentScope;
    if (building) {
      result.sourceScopes[node] = HTResolvedScope(
        HTResolvedScopeKind.module,
        null,
        node,
      );
    }
    currentScope = result.sourceScopes[node]!;
    for (final statement in node.nodes) {
      statement.accept(this);
    }
    currentScope = savedScope;
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    if (!building && node.resolvesSymbol) {
      resolveSymbol(node.id, node);
    }
  }

  @override
  void visitIntrinsicTypeExpr(IntrinsicTypeExpr node) {}

  @override
  void visitNominalTypeExpr(NominalTypeExpr node) {}

  @override
  void visitParamTypeExpr(ParamTypeExpr node) {}

  @override
  void visitFunctionTypeExpr(FuncTypeExpr node) {}

  @override
  void visitFieldTypeExpr(FieldTypeExpr node) {}

  @override
  void visitStructuralTypeExpr(StructuralTypeExpr node) {}

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr node) {}

  @override
  void visitAssignExpr(AssignExpr node) {
    if (!building && node.left is IdentifierExpr) {
      final left = node.left as IdentifierExpr;
      resolveSymbol(left.id, left);
    } else {
      node.left.accept(this);
    }
    node.right.accept(this);
  }

  @override
  void visitBlockStmt(BlockStmt node) {
    final savedScope = currentScope;
    if (node.isCodeBlock) {
      enterScope(node, HTResolvedScopeKind.block);
    }
    if (building) {
      final pending = pendingLoopVariables
          .where((variable) => identical(variable.block, node))
          .toList();
      for (final variable in pending) {
        final declared = declareVariable(
          variable.declaration,
          variable.id,
          name: variable.name,
        );
        final bindings = result.loopBindings[variable.loop];
        if (bindings != null && bindings.length == 1) {
          bindings.add(declared);
        }
      }
    }
    for (final statement in node.statements) {
      statement.accept(this);
    }
    currentScope = savedScope;
  }

  @override
  void visitForStmt(ForExpr node) {
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.block);
    final init = node.init;
    if (init != null) {
      init.initializer?.accept(this);
      if (building) {
        final marked = declareVariable(
          init,
          init.id,
          name: '${lexicon.internalPrefix}${init.id.id}',
          isSynthetic: true,
        );
        result.loopBindings[node] = [marked];
        markedLoopSymbols.add(
          _MarkedLoopSymbols(currentScope, {init.id.id: marked}),
        );
        pendingLoopVariables.add(
          _PendingLoopVariable(
            loop: node,
            block: node.loop,
            declaration: init,
            id: init.id,
            name: init.id.id,
          ),
        );
      } else {
        final marked = result.loopBindings[node]!.first;
        markedLoopSymbols.add(
          _MarkedLoopSymbols(currentScope, {init.id.id: marked}),
        );
      }
    } else if (building) {
      result.loopBindings[node] = [];
    }
    node.condition?.accept(this);
    node.increment?.accept(this);
    node.loop.accept(this);
    if (init != null) {
      markedLoopSymbols.removeLast();
    }
    currentScope = savedScope;
  }

  @override
  void visitForRangeStmt(ForRangeExpr node) {
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.block);
    node.collection.accept(this);
    if (building) {
      final iterator = declareVariable(
        node,
        node.iterator.id,
        name: '${lexicon.internalPrefix}iterator',
        isSynthetic: true,
      );
      result.loopBindings[node] = [iterator];
      pendingLoopVariables.add(
        _PendingLoopVariable(
          loop: node,
          block: node.loop,
          declaration: node.iterator,
          id: node.iterator.id,
          name: node.iterator.id.id,
        ),
      );
    }
    node.loop.accept(this);
    currentScope = savedScope;
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    if (!building) {
      result.dynamicOperations.add(node);
      requireDynamicScope();
      resolveSymbol(node.symbol, node);
    }
  }

  @override
  void visitDeleteSubStmt(DeleteSubStmt node) {
    node.object.accept(this);
    node.key.accept(this);
  }

  @override
  void visitImportExportDecl(ImportExportDecl node) {
    if (building && node.alias != null) {
      declareVariable(node, node.alias!);
    }
  }

  @override
  void visitNamespaceDecl(NamespaceDecl node) {
    if (building) {
      declareVariable(node, node.id);
      requireDynamicScope();
    }
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.dynamic);
    node.definition.accept(this);
    currentScope = savedScope;
  }

  @override
  void visitExtensionDecl(ExtensionDecl node) {
    if (building) {
      requireDynamicScope();
    }
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.dynamic);
    node.definition.accept(this);
    currentScope = savedScope;
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl node) {}

  @override
  void visitVarDecl(VarDecl node) {
    if (building) {
      declareVariable(node, node.id);
      if (node.lateInitialize || node.lateFinalize || node.isExternal) {
        requireDynamicScope();
      }
    }
    node.initializer?.accept(this);
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    if (building) {
      requireDynamicScope();
      for (final id in node.ids.keys) {
        declareVariable(node, id);
      }
    }
    node.initializer.accept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    if (building) {
      declareVariable(node, node.id);
    }
    node.initializer?.accept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    if (building &&
        node.category != FunctionCategory.literal &&
        node.id != null) {
      declareVariable(node, node.id!);
    }
    for (final param in node.paramDecls) {
      param.initializer?.accept(this);
    }
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.function);
    if (building &&
        (node.isExternal ||
            (node.category != FunctionCategory.normal &&
                node.category != FunctionCategory.literal))) {
      requireDynamicScope();
    }
    if (building) {
      for (final param in node.paramDecls) {
        declareVariable(param, param.id);
      }
    }
    node.redirectingConstructorCall?.accept(this);
    node.definition?.accept(this);
    currentScope = savedScope;
  }

  @override
  void visitClassDecl(ClassDecl node) {
    if (building) {
      declareVariable(node, node.id);
      requireDynamicScope();
    }
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.dynamic);
    node.definition.accept(this);
    currentScope = savedScope;
  }

  @override
  void visitEnumDecl(EnumDecl node) {
    if (building) {
      declareVariable(node, node.id);
      requireDynamicScope();
    }
  }

  @override
  void visitStructDecl(StructDecl node) {
    if (building) {
      declareVariable(node, node.id);
      requireDynamicScope();
    }
    final savedScope = currentScope;
    enterScope(node, HTResolvedScopeKind.dynamic);
    for (final definition in node.definition) {
      definition.accept(this);
    }
    currentScope = savedScope;
  }
}
