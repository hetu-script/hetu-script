import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('functions -', () {
    test('nested & anonymous', () async {
      final result = await hetu.eval('''
        fun functionAssign {

          fun convert(n) -> num {
            return num.parse(n)
          }

          const a: fun(num) -> num = convert

          return a.type.toString()
        }
      ''', invokeFunc: 'functionAssign');
      expect(
        result,
        'fun(any) -> num',
      );
    });
    test('extends check', () async {
      final result = await hetu.eval(r'''
        class Super2 {
          var name = 'Super'
        }
        class Extend2 extends Super2 {
          var name = 'Extend'
        }
        fun extendsCheck {
          var a = Extend2()
          return a is Super2
        }
      ''', invokeFunc: 'extendsCheck');
      expect(
        result,
        true,
      );
    });
  });
}
