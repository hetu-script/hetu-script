import '../ast/ast.dart';
import '../ast/visitor/recursive_ast_visitor.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../optimization/optimization_result.dart';
import 'compilation_context.dart';

class HTLowering extends RecursiveASTVisitor<void> {
  final HTCompilationContext _context;
  final HTLexicon _lexicon;

  HTLowering(this._context, {HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTLexiconHetu();

  static HTCompilationContext lowerCompilation(
    ASTCompilation compilation,
    HTOptimizationResult optimization, {
    HTLexicon? lexicon,
  }) {
    final context = HTCompilationContext(optimization);
    compilation.accept(HTLowering(context, lexicon: lexicon));
    return context;
  }

  T _record<T extends ASTNode>(T node, ASTNode origin) {
    return _context.recordSynthetic(node, origin);
  }

  IdentifierExpr _memberKey(String id, ASTNode origin) {
    return _record(
      IdentifierExpr(
        id,
        isLocal: false,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  MemberExpr _member(ASTNode object, String key, ASTNode origin) {
    return _record(
      MemberExpr(
        object,
        _memberKey(key, origin),
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  ASTLiteralInteger _one(ASTNode origin) {
    return _record(
      ASTLiteralInteger(
        1,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  BinaryExpr _binary(ASTNode left, String op, ASTNode right, ASTNode origin) {
    return _record(
      BinaryExpr(
        left,
        op,
        right,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  AssignExpr _assign(ASTNode left, ASTNode right, ASTNode origin) {
    return _record(
      AssignExpr(
        left,
        _lexicon.assign,
        right,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  GroupExpr _group(ASTNode inner, ASTNode origin) {
    return _record(
      GroupExpr(
        inner,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  AssignExpr _incrementAssignment(ASTNode object, String op, ASTNode origin) {
    return _assign(object, _binary(object, op, _one(origin), origin), origin);
  }

  BlockStmt _loopBlock(BlockStmt origin, ASTNode declaration) {
    return _record(
      BlockStmt(
        [declaration, ...origin.statements],
        isCodeBlock: origin.isCodeBlock,
        id: origin.id,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  VarDecl _iterationDeclaration(VarDecl origin, ASTNode initializer) {
    return _record(
      VarDecl(
        origin.id,
        internalName: origin.internalName,
        classId: origin.classId,
        declType: origin.declType,
        initializer: initializer,
        hasEndOfStmtMark: origin.hasEndOfStmtMark,
        isConst: origin.isConst,
        isStructField: origin.isStructField,
        isExternal: origin.isExternal,
        isStatic: origin.isStatic,
        isMutable: origin.isMutable,
        isPrivate: origin.isPrivate,
        isTopLevel: origin.isTopLevel,
        isField: origin.isField,
        lateFinalize: origin.lateFinalize,
        lateInitialize: origin.lateInitialize,
        source: origin.source,
        line: origin.line,
        column: origin.column,
        offset: origin.offset,
        length: origin.length,
      ),
      origin,
    );
  }

  @override
  void visitForStmt(ForExpr node) {
    final userDecl = node.init;
    VarDecl? initializer;
    BlockStmt loop = node.loop;
    final markedSymbols = <String, String>{};
    if (userDecl != null) {
      final markedVariable = _context.optimization.loopBindings[node]!.first;
      final markedId = '${_lexicon.internalPrefix}${userDecl.id.id}';
      markedSymbols[userDecl.id.id] = markedId;
      initializer = _record(
        VarDecl(
          _context.declarationIdentifier(markedId, markedVariable, userDecl.id),
          initializer: userDecl.initializer,
          isMutable: userDecl.isMutable,
          source: userDecl.source,
          line: userDecl.line,
          column: userDecl.column,
          offset: userDecl.offset,
          length: userDecl.length,
        ),
        userDecl,
      );
      final capturedInit =
          _context.referenceIdentifier(markedId, markedVariable, userDecl.id);
      final capturedDecl = _record(
        VarDecl(
          userDecl.id,
          initializer: capturedInit,
          source: userDecl.source,
          line: userDecl.line,
          column: userDecl.column,
          offset: userDecl.offset,
          length: userDecl.length,
        ),
        userDecl,
      );
      loop = _loopBlock(node.loop, capturedDecl);
    }
    final condition = node.condition ??
        _record(
          ASTLiteralBoolean(
            true,
            source: node.source,
            line: node.line,
            column: node.column,
            offset: node.offset,
            length: node.length,
          ),
          node,
        );
    _context.recordForLoop(
      node,
      HTForLowering(
        initializer: initializer,
        condition: condition,
        increment: node.increment,
        loop: loop,
        markedSymbols: markedSymbols,
      ),
    );
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeExpr node) {
    final iterVariable = _context.optimization.loopBindings[node]!.first;
    final iterId = _context.nextIteratorId();
    final collection = node.iterateValue
        ? _member(node.collection, _lexicon.idValues, node.collection)
        : node.collection;
    final iterInit = _member(collection, _lexicon.idIterator, node.iterator);
    final iterator = _record(
      VarDecl(
        _context.declarationIdentifier(iterId, iterVariable, node.iterator.id),
        initializer: iterInit,
        source: node.iterator.source,
        line: node.iterator.line,
        column: node.iterator.column,
        offset: node.iterator.offset,
        length: node.iterator.length,
      ),
      node.iterator,
    );
    final condition = _record(
      CallExpr(
        _member(
          _context.referenceIdentifier(iterId, iterVariable, node.iterator),
          _lexicon.idMoveNext,
          node.iterator,
        ),
        source: node.source,
        line: node.line,
        column: node.column,
        offset: node.offset,
        length: node.length,
      ),
      node,
    );
    final current = _member(
      _context.referenceIdentifier(iterId, iterVariable, node.iterator),
      _lexicon.idCurrent,
      node.iterator,
    );
    final item = _iterationDeclaration(node.iterator, current);
    _context.recordForRangeLoop(
      node,
      HTForRangeLowering(
        iterator: iterator,
        condition: condition,
        loop: _loopBlock(node.loop, item),
      ),
    );
    node.subAccept(this);
  }

  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    final op = node.op == _lexicon.preIncrement
        ? _lexicon.add
        : node.op == _lexicon.preDecrement
            ? _lexicon.subtract
            : null;
    if (op != null) {
      _context.recordExpression(
        node,
        _group(_incrementAssignment(node.object, op, node), node),
      );
    }
    node.subAccept(this);
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    final isIncrement = node.op == _lexicon.postIncrement;
    if (isIncrement || node.op == _lexicon.postDecrement) {
      final assignment = _group(
        _incrementAssignment(
          node.object,
          isIncrement ? _lexicon.add : _lexicon.subtract,
          node,
        ),
        node,
      );
      final result = _binary(
        assignment,
        isIncrement ? _lexicon.subtract : _lexicon.add,
        _one(node),
        node,
      );
      _context.recordExpression(node, _group(result, node));
    }
    node.subAccept(this);
  }

  @override
  void visitAssignExpr(AssignExpr node) {
    if (node.op == _lexicon.assignIfNull) {
      final condition = _binary(
        node.left,
        _lexicon.equal,
        _record(
          ASTLiteralNull(
            source: node.source,
            line: node.line,
            column: node.column,
            offset: node.offset,
            length: node.length,
          ),
          node,
        ),
        node,
      );
      _context.recordExpression(
        node,
        _record(
          IfExpr(
            condition,
            _assign(node.left, node.right, node),
            source: node.source,
            line: node.line,
            column: node.column,
            offset: node.offset,
            length: node.length,
          ),
          node,
        ),
      );
    } else if (node.op != _lexicon.assign) {
      final expanded = _assign(
        node.left,
        _binary(
          node.left,
          node.op.substring(0, node.op.length - 1),
          _group(node.right, node),
          node,
        ),
        node,
      );
      _context.recordExpression(node, expanded);
    }
    node.subAccept(this);
  }

  @override
  void visitBinaryExpr(BinaryExpr node) {
    final isNegated = node.op == _lexicon.kNotIn;
    if (node.op == _lexicon.kIn || isNegated) {
      final call = _record(
        CallExpr(
          _member(node.right, _lexicon.idContains, node),
          positionalArgs: [node.left],
          source: node.source,
          line: node.line,
          column: node.column,
          offset: node.offset,
          length: node.length,
        ),
        node,
      );
      final lowered = isNegated
          ? _record(
              UnaryPrefixExpr(
                _lexicon.logicalNot,
                call,
                source: node.source,
                line: node.line,
                column: node.column,
                offset: node.offset,
                length: node.length,
              ),
              node,
            )
          : call;
      _context.recordExpression(node, lowered);
    }
    node.subAccept(this);
  }
}
