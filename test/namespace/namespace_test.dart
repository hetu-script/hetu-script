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
}
