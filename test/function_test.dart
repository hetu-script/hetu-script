import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('functions -', () {
    test('closure', () async {
      final result = await hetu.eval('''
            fun literalFunction(func) {
              var i = 42
              fun nested () {
                i = i + 1
                return (func(i))
              }
              return nested
            }
            fun closure {
              var func = literalFunction( fun (n) => n * n )
              func()
              return func()
            }
      ''', invokeFunc: 'closure');
      expect(
        result,
        1936,
      );
    });
  });
}
