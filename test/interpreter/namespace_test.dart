import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(
      normalizeImportPath: false,
      allowImplicitNullToZeroConversion: true,
    ),
  );
  hetu.init();

  group('namespace tests -', () {
    test('automatic semicolon insertion', () {
      sourceContext.addResource('file1.ht', HTSource('''
    fun test () {
      print('Hello, World!');
    }
  '''));

      final result = hetu.eval(r'''
    import 'file1.ht' as file1
    file1.keys
''');

      expect(
        result,
        ['test'],
      );
    });
  });

  group('cross-module variable access -', () {
    test('const array from module used in compound assignment', () {
      sourceContext.addResource('cross_mod_a.ht', HTSource('''
    const arr = ['a', 'b', 'c', 'd']
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_a.ht'

    var a = 'xx'
    a += Random().nextIterable(arr)
    a.startsWith('xx')
  ''');

      expect(result, isTrue);
    });

    test('const array from module accessed multiple times', () {
      sourceContext.addResource('cross_mod_b.ht', HTSource('''
    const items = ['1', '2', '3']
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_b.ht'

    var x = Random().nextIterable(items)
    var y = Random().nextIterable(items)
    items.contains(x) && items.contains(y)
  ''');

      expect(result, isTrue);
    });

    test('mutable array from module used in compound assignment', () {
      sourceContext.addResource('cross_mod_c.ht', HTSource('''
    var values = ['10', '20', '30']
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_c.ht'

    var prefix = 'val:'
    prefix += Random().nextIterable(values)
    prefix.startsWith('val:')
  ''');

      expect(result, isTrue);
    });

    test('multiple const arrays from different modules', () {
      sourceContext.addResource('cross_mod_d.ht', HTSource('''
    const listA = ['x', 'y', 'z']
  '''));
      sourceContext.addResource('cross_mod_e.ht', HTSource('''
    const listB = ['1', '2', '3']
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_d.ht'
    import 'cross_mod_e.ht'

    var result = Random().nextIterable(listA)
    result += Random().nextIterable(listB)
    result
  ''');

      expect(result, isA<String>());
      expect(result.length, 2);
    });

    test('const variable from module used as function argument', () {
      sourceContext.addResource('cross_mod_f.ht', HTSource('''
    const limit = 42
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_f.ht'

    function doubleIt(n) {
      return n * 2
    }
    doubleIt(limit)
  ''');

      expect(result, 84);
    });

    test('named struct from module is eagerly resolved', () {
      sourceContext.addResource('cross_mod_g.ht', HTSource('''
    struct Point {
      var x = 10
      var y = 20
    }
  '''));

      final result = hetu.eval(r'''
    import 'cross_mod_g.ht'

    var p = Point()
    p.x + p.y
  ''');

      expect(result, 30);
    });
  });

  group('import hoisting -', () {
    test('imported symbol is usable before the import statement', () {
      sourceContext.addResource('hoist_a.ht', HTSource('''
    fun hoistedValue() {
      return 99
    }
  '''));

      // imports are hoisted to the start of the file by the compiler,
      // so referencing the symbol before the import statement works.
      final result = hetu.eval(r'''
    var hoistedResult = hoistedValue()
    import 'hoist_a.ht'
    hoistedResult
  ''');

      expect(result, 99);
    });

    test('circular imports: cross-cycle function calls', () {
      sourceContext.addResource('circ_a.ht', HTSource('''
    import 'circ_b.ht'

    fun circFa(n) {
      return n <= 0 ? 'done' : circFb(n - 1)
    }
  '''));
      sourceContext.addResource('circ_b.ht', HTSource('''
    import 'circ_a.ht'

    fun circFb(n) {
      return n <= 0 ? 'done' : circFa(n - 1)
    }
  '''));

      final result = hetu.eval(r'''
    import 'circ_a.ht'
    circFa(3)
  ''');

      expect(result, 'done');
    });

    test('circular imports: variable visible after flush', () {
      sourceContext.addResource('circ_c.ht', HTSource('''
    import 'circ_d.ht'

    var valueC = 'fromC'

    fun readD() {
      return valueD
    }
  '''));
      sourceContext.addResource('circ_d.ht', HTSource('''
    import 'circ_c.ht'

    var valueD = 'fromD'
  '''));

      // entry imports circ_c only; circ_d's pending import of circ_c
      // is flushed as soon as circ_c's namespace is registered.
      final result = hetu.eval(r'''
    import 'circ_c.ht'
    '${readD()}:${valueC}'
  ''');

      expect(result, 'fromD:fromC');
    });

    test('export from re-exports symbols', () {
      sourceContext.addResource('exp_a.ht', HTSource('''
    fun helperForExport() {
      return 7
    }
  '''));
      sourceContext.addResource('exp_b.ht', HTSource('''
    export { helperForExport } from 'exp_a.ht'
  '''));

      final result = hetu.eval(r'''
    import 'exp_b.ht'
    helperForExport()
  ''');

      expect(result, 7);
    });
  });
}
