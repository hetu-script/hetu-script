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
          const a: fun (num) -> num = convert
          return a.valueType.toString()
        }
      ''', invokeFunc: 'functionAssign1');
      expect(
        result,
        'function(any) -> num',
      );
    });
    test('return type', () async {
      final result = await hetu.eval('''
        fun functionAssign2 {
          var a: fun (num) -> num = fun (n: any) -> num { return n }
          return a.valueType.toString()
        }
      ''', invokeFunc: 'functionAssign2');
      expect(
        result,
        'function(any) -> num',
      );
    });
    test('function type', () async {
      final result = await hetu.eval('''
        fun functionType {
          var numparse: fun (str) -> num = fun (value: str) -> num { return num.parse(value) }
          var getType = fun { return numparse.valueType }
          var funcTypedef2 = getType()
          var strlength: funcTypedef2 = fun (value: str) -> num { return value.length }
          return strlength('hello world')
        }
      ''', invokeFunc: 'functionType');
      expect(
        result,
        11,
      );
    });
  });
}