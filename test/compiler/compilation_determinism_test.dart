import 'dart:typed_data';

import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/ast/visitor/recursive_ast_visitor.dart';
import 'package:hetu_script/hetu_script.dart';
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
  final forLoops = <ForExpr>[];
  final forRangeLoops = <ForRangeExpr>[];

  @override
  void visitForStmt(ForExpr node) {
    forLoops.add(node);
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeExpr node) {
    forRangeLoops.add(node);
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
    HTSource(source, filename: 'determinism.ht'),
    errorHandled: true,
  );
  expect(compilation.errors, isEmpty);
  return compilation;
}

dynamic _invoke(Uint8List bytes, String module, String function) {
  final hetu = _createHetu();
  hetu.loadBytecode(bytes: bytes, module: module);
  return hetu.invoke(function, module: module);
}

List<String> _stringConstants(Uint8List bytes, String module) {
  final hetu = _createHetu();
  hetu.loadBytecode(bytes: bytes, module: module);
  return List<String>.from(
      hetu.interpreter.getBytecode(module)!.constants[String]!);
}

void main() {
  test('increment and compound assignment can recompile the same AST', () {
    final hetu = _createHetu();
    final compilation = _bundle(hetu, r'''
      function run() {
        var value = 1
        final previous = value++
        value += 2
        return [previous, value]
      }
    ''');

    final first = hetu.compiler.compile(compilation);
    final second = hetu.compiler.compile(compilation);

    expect(_invoke(first, 'increment_first', 'run'), [1, 4]);
    expect(_invoke(second, 'increment_second', 'run'), [1, 4]);
  });

  group('known defect: loop lowering must be compilation-local', () {
    test('for and for-in compilation leaves original AST nodes unchanged', () {
      final hetu = _createHetu();
      final compilation = _bundle(hetu, _loopSource);
      final loops = _LoopCollector();
      compilation.accept(loops);
      final forLoop = loops.forLoops.single;
      final forRangeLoop = loops.forRangeLoops.single;
      final forStatements = List<ASTNode>.of(forLoop.loop.statements);
      final forRangeStatements = List<ASTNode>.of(forRangeLoop.loop.statements);
      final iteratorInitializer = forRangeLoop.iterator.initializer;

      hetu.compiler.compile(compilation);

      expect(forLoop.loop.statements, hasLength(forStatements.length));
      for (var i = 0; i < forStatements.length; ++i) {
        expect(identical(forLoop.loop.statements[i], forStatements[i]), isTrue);
      }
      expect(
          forRangeLoop.loop.statements, hasLength(forRangeStatements.length));
      for (var i = 0; i < forRangeStatements.length; ++i) {
        expect(
            identical(forRangeLoop.loop.statements[i], forRangeStatements[i]),
            isTrue);
      }
      expect(identical(forRangeLoop.iterator.initializer, iteratorInitializer),
          isTrue);
    },
        skip:
            'Known stage 2 defect: compiler inserts declarations into the AST');

    test('the same loop AST can be compiled repeatedly with stable behavior',
        () {
      final hetu = _createHetu();
      final compilation = _bundle(hetu, _loopSource);

      final first = hetu.compiler.compile(compilation);
      final second = hetu.compiler.compile(compilation);

      expect(_invoke(first, 'loop_first', 'run'), 9);
      expect(_invoke(second, 'loop_second', 'run'), 9);
    },
        skip:
            'Known stage 2 defect: repeated compilation changes loop bindings');

    test('independent compilations do not inherit static synthetic counters',
        () {
      final source = _loopSource.replaceFirst(
        'return total',
        'var temporary = 0; delete temporary; return total',
      );
      final first = _createHetu().compile(source, filename: 'first.ht');
      final second = _createHetu().compile(source, filename: 'first.ht');

      expect(_invoke(first, 'independent_first', 'run'), 9);
      expect(_invoke(second, 'independent_second', 'run'), 9);
      expect(_stringConstants(second, 'constants_second'),
          _stringConstants(first, 'constants_first'));
    },
        skip:
            'Known stage 2 defect: static iterIndex affects independent output');
  });
}
