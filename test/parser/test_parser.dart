import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/ast/ast.dart';

/// Helper: parse [code] as a script and return the AST source.
ASTSource parse(String code) {
  final source = HTSource(code, type: HTResourceType.hetuScript);
  final parser = HTParserHetu();
  return parser.parseSource(source);
}

/// Helper: parse [code] as a module and return the AST source.
ASTSource parseModule(String code) {
  final source = HTSource(code, type: HTResourceType.hetuModule);
  final parser = HTParserHetu();
  return parser.parseSource(source);
}

/// Helper: parse [code] as an expression.
List<ASTNode> parseExpr(String code) {
  final source = HTSource(code, type: HTResourceType.hetuLiteralCode);
  final parser = HTParserHetu();
  final lexer = parser.lexer;
  final tokens = lexer.lex(code);
  return parser.parseTokens(tokens, source: source, style: ParseStyle.expression);
}

/// Helper: assert that [code] parses without errors and returns at least one node.
void expectValid(String code) {
  final result = parse(code);
  expect(result.errors, isEmpty, reason: 'errors: ${result.errors.map((e) => e.toString())}');
  expect(result.nodes, isNotEmpty);
}

/// Helper: assert that [code] parses and produces at least one error.
void expectError(String code) {
  final result = parse(code);
  expect(result.errors, isNotEmpty, reason: 'expected errors but got none');
}

void main() {
  // ============================================================
  // Literal expressions
  // ============================================================
  group('literal expressions', () {
    test('null', () {
      final nodes = parseExpr('null');
      expect(nodes.single, isA<ASTLiteralNull>());
    });

    test('boolean true', () {
      final nodes = parseExpr('true');
      final lit = nodes.single as ASTLiteralBoolean;
      expect(lit.value, isTrue);
    });

    test('boolean false', () {
      final nodes = parseExpr('false');
      final lit = nodes.single as ASTLiteralBoolean;
      expect(lit.value, isFalse);
    });

    test('integer', () {
      final nodes = parseExpr('42');
      final lit = nodes.single as ASTLiteralInteger;
      expect(lit.value, 42);
    });

    test('float', () {
      final nodes = parseExpr('3.14');
      final lit = nodes.single as ASTLiteralFloat;
      expect(lit.value, 3.14);
    });

    test('string single-quoted', () {
      final nodes = parseExpr("'hello'");
      final lit = nodes.single as ASTLiteralString;
      expect(lit.value, 'hello');
    });

    test('string double-quoted', () {
      final nodes = parseExpr('"world"');
      final lit = nodes.single as ASTLiteralString;
      expect(lit.value, 'world');
    });

    test('string interpolation', () {
      final nodes = parseExpr(r"'${1 + 2}'");
      expect(nodes.single, isA<ASTStringInterpolation>());
    });
  });

  // ============================================================
  // Identifier expressions
  // ============================================================
  group('identifier expressions', () {
    test('simple identifier', () {
      final nodes = parseExpr('foo');
      final id = nodes.single as IdentifierExpr;
      expect(id.id, 'foo');
    });

    test('backtick identifier', () {
      final nodes = parseExpr('`weird name`');
      final id = nodes.single as IdentifierExpr;
      expect(id.id, 'weird name');
    });

    test('this expression', () {
      final nodes = parseExpr('this');
      final id = nodes.single as IdentifierExpr;
      expect(id.id, 'this');
    });
  });

  // ============================================================
  // Unary prefix expressions
  // ============================================================
  group('unary prefix expressions', () {
    test('logical not', () {
      final nodes = parseExpr('!true');
      final expr = nodes.single as UnaryPrefixExpr;
      expect(expr.op, '!');
      expect(expr.object, isA<ASTLiteralBoolean>());
    });

    test('negation of identifier', () {
      final nodes = parseExpr('-x');
      final expr = nodes.single as UnaryPrefixExpr;
      expect(expr.op, '-');
      expect(expr.object, isA<IdentifierExpr>());
    });

    test('pre-increment', () {
      final nodes = parseExpr('++x');
      final expr = nodes.single as UnaryPrefixExpr;
      expect(expr.op, '++');
    });

    test('pre-decrement', () {
      final nodes = parseExpr('--x');
      final expr = nodes.single as UnaryPrefixExpr;
      expect(expr.op, '--');
    });

    test('bitwise not', () {
      final nodes = parseExpr('~0');
      final expr = nodes.single as UnaryPrefixExpr;
      expect(expr.op, '~');
    });
  });

  // ============================================================
  // Unary postfix expressions
  // ============================================================
  group('unary postfix expressions', () {
    test('post-increment', () {
      final nodes = parseExpr('x++');
      final expr = nodes.single as UnaryPostfixExpr;
      expect(expr.op, '++');
    });

    test('post-decrement', () {
      final nodes = parseExpr('x--');
      final expr = nodes.single as UnaryPostfixExpr;
      expect(expr.op, '--');
    });

    test('member access', () {
      final nodes = parseExpr('obj.prop');
      final expr = nodes.single as MemberExpr;
      expect(expr.object, isA<IdentifierExpr>());
      expect(expr.key.id, 'prop');
    });

    test('nullable member access', () {
      final nodes = parseExpr('obj?.prop');
      final expr = nodes.single as MemberExpr;
      expect(expr.isNullable, isTrue);
    });

    test('subscript', () {
      final nodes = parseExpr('arr[0]');
      final expr = nodes.single as SubExpr;
      expect(expr.object, isA<IdentifierExpr>());
      expect(expr.key, isA<ASTLiteralInteger>());
    });

    test('nullable subscript', () {
      final nodes = parseExpr('arr?[0]');
      final expr = nodes.single as SubExpr;
      expect(expr.isNullable, isTrue);
    });

    test('function call', () {
      final nodes = parseExpr('foo(1, 2)');
      final expr = nodes.single as CallExpr;
      expect(expr.positionalArgs, hasLength(2));
    });

    test('nullable function call', () {
      final nodes = parseExpr('foo?(1)');
      final expr = nodes.single as CallExpr;
      expect(expr.isNullable, isTrue);
    });

    test('named arguments', () {
      final nodes = parseExpr('foo(a: 1, b: 2)');
      final expr = nodes.single as CallExpr;
      expect(expr.namedArgs, contains('a'));
      expect(expr.namedArgs, contains('b'));
    });

    test('chained postfix', () {
      final nodes = parseExpr('a.b()');
      final expr = nodes.single as CallExpr;
      expect(expr.callee, isA<MemberExpr>());
    });

    test('spread argument', () {
      final nodes = parseExpr('foo(...args)');
      final expr = nodes.single as CallExpr;
      expect(expr.positionalArgs.single, isA<SpreadExpr>());
    });
  });

  // ============================================================
  // Binary expressions — precedence & associativity
  // ============================================================
  group('binary expressions', () {
    test('additive', () {
      final nodes = parseExpr('1 + 2');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '+');
      expect(expr.left, isA<ASTLiteralInteger>());
      expect(expr.right, isA<ASTLiteralInteger>());
    });

    test('additive left-associative', () {
      final nodes = parseExpr('1 + 2 + 3');
      final expr = nodes.single as BinaryExpr;
      expect(expr.left, isA<BinaryExpr>()); // (1 + 2) + 3
      expect(expr.right, isA<ASTLiteralInteger>());
    });

    test('multiplicative has higher precedence than additive', () {
      final nodes = parseExpr('1 + 2 * 3');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '+');
      expect(expr.right, isA<BinaryExpr>()); // 2 * 3
    });

    test('comparison', () {
      final nodes = parseExpr('a > b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '>');
    });

    test('equality', () {
      final nodes = parseExpr('a == b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '==');
    });

    test('logical and', () {
      final nodes = parseExpr('a && b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '&&');
    });

    test('logical or', () {
      final nodes = parseExpr('a || b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '||');
    });

    test('bitwise and', () {
      final nodes = parseExpr('a & b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '&');
    });

    test('bitwise or', () {
      final nodes = parseExpr('a | b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '|');
    });

    test('bitwise xor', () {
      final nodes = parseExpr('a ^ b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '^');
    });

    test('left shift', () {
      final nodes = parseExpr('a << b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '<<');
    });

    test('right shift', () {
      final nodes = parseExpr('a >> b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '>>');
    });

    test('strict equality', () {
      final nodes = parseExpr('a === b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '===');
    });

    test('is type check', () {
      final nodes = parseExpr('a is string');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, 'is');
    });

    test('is not type check', () {
      final nodes = parseExpr('a is! string');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, 'is!');
    });

    test('in check', () {
      final nodes = parseExpr('a in list');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, 'in');
    });

    test('not in check', () {
      final nodes = parseExpr('a in! list');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, 'in!');
    });
  });

  // ============================================================
  // Ternary and if-null expressions
  // ============================================================
  group('ternary and if-null', () {
    test('ternary', () {
      final nodes = parseExpr('a ? b : c');
      final expr = nodes.single as TernaryExpr;
      expect(expr.condition, isA<IdentifierExpr>());
      expect(expr.thenBranch, isA<IdentifierExpr>());
      expect(expr.elseBranch, isA<IdentifierExpr>());
    });

    test('if-null', () {
      final nodes = parseExpr('a ?? b');
      final expr = nodes.single as BinaryExpr;
      expect(expr.op, '??');
    });
  });

  // ============================================================
  // Assignment expressions
  // ============================================================
  group('assignment expressions', () {
    test('simple assignment', () {
      final nodes = parseExpr('x = 42');
      final expr = nodes.single as AssignExpr;
      expect(expr.op, '=');
    });

    test('compound assignment', () {
      final nodes = parseExpr('x += 1');
      final expr = nodes.single as AssignExpr;
      expect(expr.op, '+=');
    });
  });

  // ============================================================
  // Group, list, struct object and new expressions
  // ============================================================
  group('composite expressions', () {
    test('group expression', () {
      final nodes = parseExpr('(1 + 2)');
      final expr = nodes.single as GroupExpr;
      expect(expr.inner, isA<BinaryExpr>());
    });

    test('list expression', () {
      final nodes = parseExpr('[1, 2, 3]');
      final expr = nodes.single as ListExpr;
      expect(expr.list, hasLength(3));
    });

    test('empty list', () {
      final nodes = parseExpr('[]');
      final expr = nodes.single as ListExpr;
      expect(expr.list, isEmpty);
    });

    test('struct object', () {
      final nodes = parseExpr(r'{a: 1, b: 2}');
      final expr = nodes.single as StructObjExpr;
      expect(expr.fields, hasLength(2));
    });

    test('struct object with keyword', () {
      final nodes = parseExpr('struct {a: 1}');
      expect(nodes.single, isA<StructObjExpr>());
    });

    test('new expression', () {
      final nodes = parseExpr('new Foo(1, 2)');
      final expr = nodes.single as CallExpr;
      expect(expr.hasNewOperator, isTrue);
    });
  });

  // ============================================================
  // If expression / statement
  // ============================================================
  group('if', () {
    test('if statement', () {
      expectValid('if (x) { y }');
    });

    test('if-else statement', () {
      expectValid('if (x) { y } else { z }');
    });

    test('if expression', () {
      final nodes = parseExpr('if (x) 1 else 2');
      expect(nodes.single, isA<IfExpr>());
    });
  });

  // ============================================================
  // While / do-while
  // ============================================================
  group('while', () {
    test('while statement', () {
      expectValid('while (true) { break }');
    });

    test('do-while statement', () {
      expectValid('do { break } while (true)');
    });
  });

  // ============================================================
  // For loops
  // ============================================================
  group('for', () {
    test('for c-style', () {
      expectValid('for (var i = 0; i < 10; i++) { }');
    });

    test('for in', () {
      expectValid('for (var item in items) { }');
    });

    test('for of', () {
      expectValid('for (var item of items) { }');
    });

    test('for empty', () {
      expectValid('for (;;) { break }');
    });
  });

  // ============================================================
  // Switch
  // ============================================================
  group('switch', () {
    test('switch statement', () {
      expectValid('switch (x) { 1 => {} 2 => {} else => {} }');
    });

    test('switch expression', () {
      final nodes = parseExpr('switch (x) { 1 => "a" else => "b" }');
      expect(nodes.single, isA<SwitchStmt>());
    });
  });

  // ============================================================
  // Variable declarations
  // ============================================================
  group('variable declarations', () {
    test('var with initializer', () {
      expectValid('var x = 42');
    });

    test('var with type', () {
      expectValid('var x: int = 42');
    });

    test('var without initializer', () {
      expectValid('var x');
    });

    test('immutable (val/let)', () {
      expectValid('val x = 42');
    });

    test('const', () {
      expectValid('const x = 42');
    });

    test('late', () {
      expectValid('late x');
    });
  });

  // ============================================================
  // Destructuring declarations
  // ============================================================
  group('destructuring declarations', () {
    test('list destructuring', () {
      expectValid('var [a, b] = [1, 2]');
    });

    test('struct destructuring', () {
      expectValid('var {a, b} = obj');
    });
  });

  // ============================================================
  // Function declarations
  // ============================================================
  group('function declarations', () {
    test('simple function', () {
      expectValid('function foo() {}');
    });

    test('function with params', () {
      expectValid('function add(a, b) { return a + b }');
    });

    test('function with return type', () {
      expectValid('function foo() -> int { return 42 }');
    });

    test('async function', () {
      expectValid('async function foo() {}');
    });

    test('function with optional params', () {
      expectValid('function foo(a, [b, c]) {}');
    });

    test('function with named params', () {
      expectValid('function foo(a, {b, c}) {}');
    });

    test('function with variadic param', () {
      expectValid('function foo(...args) {}');
    });

    test('literal function (lambda arrow)', () {
      expectValid('var f = (x) => x + 1');
    });

    test('literal function (block body)', () {
      expectValid('var f = (x) { return x + 1 }');
    });

    test('literal async function', () {
      expectValid('var f = async (x) => x + 1');
    });

    test('getter', () {
      expectValid('class Foo { get x => 42 }');
    });

    test('setter', () {
      expectValid('class Foo { set x(v) {} }');
    });

    test('constructor', () {
      expectValid('class Foo { constructor () {} }');
    });

    test('named constructor', () {
      expectValid('class Foo { constructor bar () {} }');
    });
  });

  // ============================================================
  // Class declarations
  // ============================================================
  group('class declarations', () {
    test('simple class', () {
      expectValid('class Foo {}');
    });

    test('class with extends', () {
      expectValid('class Foo extends Bar {}');
    });

    test('abstract class', () {
      expectValid('abstract class Foo {}');
    });

    test('external class', () {
      expectValid('external class Foo {}');
    });

    test('class with members', () {
      expectValid('''
        class Person {
          var name: string
          constructor (n: string) { name = n }
          function greet() { return "hello" }
        }
      ''');
    });
  });

  // ============================================================
  // Enum declarations
  // ============================================================
  group('enum declarations', () {
    test('simple enum', () {
      expectValid('enum Color { red, green, blue }');
    });

    test('external enum', () {
      expectValid('external enum Color { red, green, blue }');
    });
  });

  // ============================================================
  // Struct declarations
  // ============================================================
  group('struct declarations', () {
    test('simple struct', () {
      expectValid('struct Point { var x: num var y: num }');
    });

    test('struct with prototype', () {
      expectValid('struct Dog extends Animal { var breed: string }');
    });

    test('struct with mixin', () {
      expectValid('struct Bird with Flyable, Singable { }');
    });
  });

  // ============================================================
  // Import / export
  // ============================================================
  group('import/export', () {
    test('simple import', () {
      expectValid("import 'module.ht'");
    });

    test('import with show list', () {
      expectValid("import { foo, bar } from 'module.ht'");
    });

    test('import with alias', () {
      expectValid("import 'module.ht' as m");
    });

    test('simple export', () {
      expectValid("export 'module.ht'");
    });

    test('export with show list', () {
      expectValid("export { foo, bar } from 'module.ht'");
    });
  });

  // ============================================================
  // Return / break / continue
  // ============================================================
  group('control flow', () {
    test('return with value', () {
      expectValid('function foo() { return 42 }');
    });

    test('return without value', () {
      expectValid('function foo() { return }');
    });

    test('break in loop', () {
      expectValid('while (true) { break }');
    });

    test('continue in loop', () {
      expectValid('while (true) { continue }');
    });
  });

  // ============================================================
  // Throw, assert, delete
  // ============================================================
  group('throw, assert, delete', () {
    test('throw', () {
      expectValid('throw "error"');
    });

    test('assert', () {
      expectValid('assert (true)');
    });

    test('assert with message', () {
      expectValid('assert (true, "msg")');
    });

    test('delete variable', () {
      expectValid('delete x');
    });

    test('delete member', () {
      expectValid('delete obj.prop');
    });
  });

  // ============================================================
  // Type expressions
  // ============================================================
  group('type expressions', () {
    test('nominal type', () {
      final nodes = parseExpr('typeval string');
      expect(nodes.single, isA<TypeExpr>());
    });

    test('function type', () {
      final nodes = parseExpr('typeval (int, string) -> bool');
      expect(nodes.single, isA<TypeExpr>());
    });

    test('structural type', () {
      final nodes = parseExpr('typeval {x: int, y: int}');
      expect(nodes.single, isA<TypeExpr>());
    });

    test('nullable type', () {
      final nodes = parseExpr('typeval string?');
      final type = nodes.single as NominalTypeExpr;
      expect(type.isNullable, isTrue);
    });
  });

  // ============================================================
  // Error recovery
  // ============================================================
  group('error handling', () {
    test('incomplete var declaration', () {
      expectError('var x:');
    });

    test('incomplete binary expression', () {
      expectError('1 +');
    });

    test('missing closing paren', () {
      expectError('(1 + 2');
    });

    test('assign to non-left-value', () {
      expectError('42 = x');
    });
  });

  // ============================================================
  // Comment handling
  // ============================================================
  group('comment handling', () {
    test('struct literal with comments', () {
      final result = parse('''
        {
          // names: {},
          entities: {
            // nested
          }
        }
      ''');
      expect(result.errors, isEmpty);
      expect(result.nodes, isNotEmpty);
    });

    test('line comments are consumed', () {
      expectValid('''
        // this is a comment
        var x = 1
      ''');
    });

    test('block comments are consumed', () {
      expectValid('''
        /* block comment */
        var x = 1
      ''');
    });

    test('documentation comments are consumed', () {
      expectValid('''
        /// doc comment
        var x = 1
      ''');
    });
  });

  // ============================================================
  // Module parsing
  // ============================================================
  group('module parsing', () {
    test('module allows imports and declarations', () {
      final result = parseModule('''
        import 'math.ht'
        var x = 1
      ''');
      expect(result.errors, isEmpty);
    });

    test('module rejects statements', () {
      final result = parseModule('if (true) { }');
      expect(result.errors, isNotEmpty);
    });
  });

  // ============================================================
  // Edge cases
  // ============================================================
  group('edge cases', () {
    test('empty input', () {
      final result = parse('');
      expect(result.errors, isEmpty);
    });

    test('nested blocks', () {
      expectValid('''
        if (true) {
          if (false) {
            var x = 1
          }
        }
      ''');
    });

    test('deeply nested expressions', () {
      expectValid('1 + 2 * 3 - 4 / 5 % 6 == 7 > 8 && 9 || 0');
    });

    test('trailing comma in list', () {
      expectValid('[1, 2, ]');
    });

    test('trailing comma in function args', () {
      expectValid('foo(1, 2, )');
    });

    test('multiple statements', () {
      final result = parse('''
        var x = 1
        var y = 2
        var z = x + y
      ''');
      expect(result.errors, isEmpty);
      expect(result.nodes, hasLength(3));
    });
  });
}
