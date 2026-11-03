import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/ast/visitor/recursive_ast_visitor.dart';
import 'package:hetu_script/bytecode/lowering.dart';
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

  @override
  void visitVarDecl(VarDecl node) {
    identifiers.add(node.id);
    node.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    identifiers.add(node.id);
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    final id = node.id;
    if (id != null) identifiers.add(id);
    node.subAccept(this);
  }

  @override
  void visitClassDecl(ClassDecl node) {
    identifiers.add(node.id);
    node.subAccept(this);
  }

  @override
  void visitStructDecl(StructDecl node) {
    identifiers.add(node.id);
    node.subAccept(this);
  }
}

void main() {
  test('parser and AST constructors assign distinct identifier roles', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    final compilation = hetu.bundle(
      HTSource(r'''
        var value = 1
        class Box {}
        struct Point { var x }
        function run(param) {
          var local: Box = value
          value = param
          local.x
          return local
        }
      ''', filename: 'identifier_roles.ht'),
      errorHandled: true,
    );
    final collector = _IdentifierCollector();
    compilation.accept(collector);
    final roles = <String, List<HTIdentifierRole>>{};
    for (final identifier in collector.identifiers) {
      roles.putIfAbsent(identifier.id, () => []).add(identifier.role);
    }

    expect(
        roles['value'],
        containsAll([
          HTIdentifierRole.declaration,
          HTIdentifierRole.write,
          HTIdentifierRole.read,
        ]));
    expect(
        roles['param'],
        containsAll([
          HTIdentifierRole.declaration,
          HTIdentifierRole.read,
        ]));
    expect(roles['local'], contains(HTIdentifierRole.declaration));
    expect(
        roles['Box'],
        containsAll([
          HTIdentifierRole.declaration,
          HTIdentifierRole.type,
        ]));
    expect(roles['Point'], contains(HTIdentifierRole.declaration));
    expect(roles['x'], contains(HTIdentifierRole.member));

    for (final identifier in collector.identifiers) {
      if (identifier.role == HTIdentifierRole.declaration ||
          identifier.role == HTIdentifierRole.member ||
          identifier.role == HTIdentifierRole.type) {
        expect(identifier.resolvesSymbol, isFalse);
      }
    }
  });

  test('legacy isLocal and synthetic roles coexist without changing encoding',
      () {
    final legacyMember = IdentifierExpr('key', isLocal: false);
    final legacyRead = IdentifierExpr('value');
    expect(legacyMember.role, HTIdentifierRole.member);
    expect(legacyMember.isLocal, isFalse);
    expect(legacyRead.role, HTIdentifierRole.read);
    expect(legacyRead.isLocal, isTrue);

    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    final compilation = hetu.bundle(
      HTSource(r'''
        function run() {
          for (var i = 0; i < 1; ++i) {}
          for (final item in [1]) {}
        }
      ''', filename: 'synthetic_roles.ht'),
      errorHandled: true,
    );
    final optimization =
        HTOptimizationResolver().resolveCompilation(compilation);
    final context = HTLowering.lowerCompilation(compilation, optimization);

    for (final identifier
        in context.syntheticDeclarations.keys.whereType<IdentifierExpr>()) {
      expect(identifier.role, HTIdentifierRole.synthetic);
      expect(identifier.resolvesSymbol, isTrue);
      expect(identifier.isLocal, isTrue);
    }
    for (final identifier
        in context.syntheticReferences.keys.whereType<IdentifierExpr>()) {
      expect(identifier.role, HTIdentifierRole.synthetic);
      expect(identifier.resolvesSymbol, isTrue);
    }
  });
}
