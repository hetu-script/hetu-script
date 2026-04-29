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
  });
}
