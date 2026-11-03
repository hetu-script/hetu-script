import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/ast/visitor/recursive_ast_visitor.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/optimization/optimization_resolver.dart';
import 'package:test/test.dart';

class _IdentifierCollector extends RecursiveASTVisitor<void> {
  final identifiers = <IdentifierExpr>[];

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    identifiers.add(node);
    node.subAccept(this);
  }
}

void main() {
  test('recursive visitors and optimization resolve the same child nodes', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    final compilation = hetu.bundle(
      HTSource(r'''
        function outer(value) {
          assert(true, value)
          final [item] = value
          final object = {field: value}
          return () {
            throw value
          }
        }
        function other(value) {
          return () {
            return value
          }
        }
      ''', filename: 'ast_traversal.ht'),
      errorHandled: true,
    );
    final collector = _IdentifierCollector();
    compilation.accept(collector);
    final visited = collector.identifiers
        .where((identifier) => identifier.id == 'value')
        .toList();
    final optimization =
        HTOptimizationResolver().resolveCompilation(compilation);
    final resolved = optimization.references.keys
        .whereType<IdentifierExpr>()
        .where((identifier) => identifier.id == 'value')
        .toList();

    expect(visited, hasLength(5));
    expect(resolved, hasLength(visited.length));
    for (final identifier in visited) {
      expect(optimization.references[identifier], isNotNull);
    }
  });
}
