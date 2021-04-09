import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('type -', () {
    test('extends', () async {
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
    test('arguments', () async {
      final result = await hetu.eval('''
        fun functionAssign1 {
          fun convert(n) -> num {
            return num.parse(n)
          }
          const a: fun(num) -> num = convert
          return a.runtimeType.toString()
        }
      ''', invokeFunc: 'functionAssign1');
      expect(
        result,
        'fun(any) -> num',
      );
    });
    test('return type', () async {
      final result = await hetu.eval('''
        fun functionAssign2 {
          var a: fun(any) -> any = fun(n: num) -> num { return n + 1 }
          return a.runtimeType.toString()
        }
      ''', invokeFunc: 'functionAssign2');
      expect(
        result,
        'fun(num) -> num',
      );
    });
  });
}
