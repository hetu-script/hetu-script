import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  group('type -', () {
    test('extends', () {
      final result = hetu.eval(r'''
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
    // test('arguments', () {
    //   final result = hetu.eval('''
    //     fun functionAssign1 {
    //       fun convert(n) -> num {
    //         return num.parse(n)
    //       }
    //       const a: fun (num) -> num = convert
    //       return a.valueType.toString()
    //     }
    //   ''', invokeFunc: 'functionAssign1');
    //   expect(
    //     result,
    //     'function(any) -> num',
    //   );
    // });
    // test('return type', () {
    //   final result = hetu.eval('''
    //     fun functionAssign2 {
    //       var a: fun (num) -> num = fun (n: any) -> num { return n }
    //       return a.valueType.toString()
    //     }
    //   ''', invokeFunc: 'functionAssign2');
    //   expect(
    //     result,
    //     'function(any) -> num',
    //   );
    // });
    test('function type', () {
      final result = hetu.eval('''
        fun functionType {
          var numparse: fun (str) -> num = fun (value: str) -> num { return num.parse(value) }
          var getType = fun { typeof numparse }
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
    test('type alias class', () {
      final result = hetu.eval('''
        fun typeAlias1 {
          class A {
            var name: str
            construct (name: str) {
              this.name = name
            }
          }
          type Alias = A
          var aa = Alias('jimmy')
          return aa.name
        }
      ''', invokeFunc: 'typeAlias1');
      expect(
        result,
        'jimmy',
      );
    });
    test('type alias function', () {
      final result = hetu.eval('''
        fun typeAlias2 {
          type MyFuncType = fun (num, num) -> num
          var func: MyFuncType = fun add(a: num, b: num) -> num => a + b
          return func(6, 7)
        }
      ''', invokeFunc: 'typeAlias2');
      expect(
        result,
        13,
      );
    });
  });
}
