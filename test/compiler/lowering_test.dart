import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/ast/visitor/recursive_ast_visitor.dart';
import 'package:hetu_script/bytecode/compilation_context.dart';
import 'package:hetu_script/bytecode/lowering.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/optimization/optimization_resolver.dart';
import 'package:hetu_script/values.dart';
import 'package:test/test.dart';

const _loopSource = r'''
  function run() {
    var total = 0
    for (var i = 0; i < 3; ++i) {
      total += i
    }
    for (final item in [1, 2, 3]) {
      total += item
    }
    return total
  }
''';

class _LoopCollector extends RecursiveASTVisitor<void> {
  ForExpr? forLoop;
  ForRangeExpr? forRangeLoop;

  @override
  void visitForStmt(ForExpr node) {
    forLoop = node;
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeExpr node) {
    forRangeLoop = node;
    node.subAccept(this);
  }
}

class _ExpressionCollector extends RecursiveASTVisitor<void> {
  final prefixes = <UnaryPrefixExpr>[];
  final postfixes = <UnaryPostfixExpr>[];
  final assignments = <AssignExpr>[];
  final binaries = <BinaryExpr>[];

  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    prefixes.add(node);
    node.subAccept(this);
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    postfixes.add(node);
    node.subAccept(this);
  }

  @override
  void visitAssignExpr(AssignExpr node) {
    assignments.add(node);
    node.subAccept(this);
  }

  @override
  void visitBinaryExpr(BinaryExpr node) {
    binaries.add(node);
    node.subAccept(this);
  }
}

Hetu _createHetu() {
  final hetu = Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      processError: false,
    ),
  );
  hetu.init();
  return hetu;
}

ASTCompilation _bundle(Hetu hetu, String source) {
  final compilation = hetu.bundle(
    HTSource(source, filename: 'lowering.ht'),
    errorHandled: true,
  );
  expect(compilation.errors, isEmpty);
  return compilation;
}

HTCompilationContext _lower(ASTCompilation compilation) {
  final optimization = HTOptimizationResolver().resolveCompilation(compilation);
  return HTLowering.lowerCompilation(compilation, optimization);
}

void main() {
  test('loop lowering preserves origins and canonical binding identities', () {
    final compilation = _bundle(_createHetu(), _loopSource);
    final loops = _LoopCollector();
    compilation.accept(loops);
    final forLoop = loops.forLoop!;
    final forRangeLoop = loops.forRangeLoop!;
    final originalForStatements = List<ASTNode>.of(forLoop.loop.statements);
    final originalRangeStatements =
        List<ASTNode>.of(forRangeLoop.loop.statements);
    final originalIteratorInitializer = forRangeLoop.iterator.initializer;

    final context = _lower(compilation);
    final forLowering = context.forLoop(forLoop)!;
    final rangeLowering = context.forRangeLoop(forRangeLoop)!;
    final markedVariable = context.optimization.loopBindings[forLoop]!.first;
    final iteratorVariable =
        context.optimization.loopBindings[forRangeLoop]!.first;

    expect(forLoop.loop.statements, originalForStatements);
    expect(forRangeLoop.loop.statements, originalRangeStatements);
    expect(
        identical(
            forRangeLoop.iterator.initializer, originalIteratorInitializer),
        isTrue);
    expect(identical(forLowering.loop, forLoop.loop), isFalse);
    expect(forLowering.loop.statements,
        hasLength(originalForStatements.length + 1));
    expect(context.syntheticNodes.originOf(forLowering.loop), forLoop.loop);
    expect(context.syntheticNodes.originOf(forLowering.initializer!),
        forLoop.init!);
    expect(context.syntheticDeclarations[forLowering.initializer!.id],
        same(markedVariable));

    final capturedDecl = forLowering.loop.statements.first as VarDecl;
    expect(identical(capturedDecl.id, forLoop.init!.id), isTrue);
    expect(context.syntheticReferences[capturedDecl.initializer],
        same(markedVariable));
    expect(context.syntheticNodes.originOf(capturedDecl), forLoop.init);
    expect(capturedDecl.line, forLoop.init!.line);
    expect(identical(capturedDecl.source, forLoop.init!.source), isTrue);

    expect(context.syntheticDeclarations[rangeLowering.iterator.id],
        same(iteratorVariable));
    expect(context.syntheticNodes.originOf(rangeLowering.iterator),
        forRangeLoop.iterator);
    expect(
        context.syntheticNodes.originOf(rangeLowering.condition), forRangeLoop);
    final item = rangeLowering.loop.statements.first as VarDecl;
    expect(identical(item.id, forRangeLoop.iterator.id), isTrue);
    expect(context.syntheticNodes.originOf(item), forRangeLoop.iterator);

    final independent = _lower(compilation);
    expect(independent.iteratorCount, 1);
    expect(independent.forRangeLoop(forRangeLoop)!.iterator.id.id,
        rangeLowering.iterator.id.id);
  });

  test('expression lowering centralizes shapes and source origins', () {
    final compilation = _bundle(_createHetu(), r'''
      function run(value, values) {
        ++value
        value--
        value += 2
        value ??= 4
        value in values
        value in! values
      }
    ''');
    final expressions = _ExpressionCollector();
    compilation.accept(expressions);
    final context = _lower(compilation);

    final prefix = expressions.prefixes.single;
    final postfix = expressions.postfixes.single;
    final compound = expressions.assignments[0];
    final ifNull = expressions.assignments[1];
    final inExpr = expressions.binaries[0];
    final notInExpr = expressions.binaries[1];
    final origins = <ASTNode>[
      prefix,
      postfix,
      compound,
      ifNull,
      inExpr,
      notInExpr,
    ];

    for (final origin in origins) {
      final lowered = context.loweredExpression(origin);
      expect(lowered, isNotNull);
      expect(context.syntheticNodes.originOf(lowered!), origin);
      expect(lowered.line, origin.line);
      expect(lowered.column, origin.column);
      expect(identical(lowered.source, origin.source), isTrue);
    }
    expect(context.loweredExpression(prefix), isA<GroupExpr>());
    expect(context.loweredExpression(postfix), isA<GroupExpr>());
    expect(context.loweredExpression(compound), isA<AssignExpr>());
    expect(context.loweredExpression(ifNull), isA<IfExpr>());
    expect(context.loweredExpression(inExpr), isA<CallExpr>());
    expect(context.loweredExpression(notInExpr), isA<UnaryPrefixExpr>());
  });

  test('lowered expressions preserve literal closure and operator behavior',
      () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeCounter() {
        var count = 0
        return () {
          final prefix = ++count
          final postfix = count++
          return [prefix, postfix, count]
        }
      }
      function operators() {
        var value = 1
        value ??= 2
        value += 2
        return [value in [3], value in! [4]]
      }
    ''');
    final counter = hetu.invoke('makeCounter') as HTFunction;

    expect(counter.call(), [1, 1, 2]);
    expect(counter.call(), [3, 3, 4]);
    expect(hetu.invoke('operators'), [true, true]);
  });

  test('anonymous struct ids are isolated by interpreter instance', () {
    final first = Hetu().interpreter;
    final firstStruct = HTStruct(first);
    final secondStruct = HTStruct(first);
    final second = Hetu().interpreter;
    final independentStruct = HTStruct(second);

    expect(firstStruct.id, '__struct0');
    expect(secondStruct.id, '__struct1');
    expect(independentStruct.id, '__struct0');
  });
}
