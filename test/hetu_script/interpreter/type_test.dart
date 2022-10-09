import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('type -', () {
    test('type is operator', () {
      final result = hetu.eval(r'''
        '' is! str
      ''');
      expect(
        result,
        false,
      );
    });

    test('extends', () {
      final result = hetu.eval(r'''
        class Super2 {
          var name = 'Super'
        }
        class Extend2 extends Super2 {
          var name = 'Extend'
        }
        var a = Extend2()
        a is Super2
      ''');
      expect(
        result,
        true,
      );
    });
    // test('arguments', () {
    //   final result = hetu.eval(r'''
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
    //   final result = hetu.eval(r'''
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
      final result = hetu.eval(r'''
        var numparse: (str) -> num = fun (value: str) -> num { return num.parse(value) }
        var getType = fun { typeof numparse }
        var funcTypedef2 = getType()
        var strlength: funcTypedef2 = fun (value: str) -> num { return value.length }
        strlength('hello world')
      ''');
      expect(
        result,
        11,
      );
    });
    test('type alias class', () {
      final result = hetu.eval(r'''
        class A {
          var name: str
          construct (name: str) {
            this.name = name
          }
        }
        typedef Alias = A
        var aa = Alias('jimmy')
        aa.name
      ''');
      expect(
        result,
        'jimmy',
      );
    });
    test('type alias function', () {
      final result = hetu.eval(r'''
        typedef MyFuncType = (num, num) -> num
        var func: MyFuncType = fun add(a: num, b: num) -> num => a + b
        func(6, 7)
      ''');
      expect(
        result,
        13,
      );
    });
    test('structural type', () {
      final result = hetu.eval(r'''
        typedef ObjType = {
          name: str,
          greeting: () -> any,
        }
        var aObj: {} = {
          name: 'jimmy',
          greeting: () {
            print('hi! I\'m ${this.name}')
          }
        }
        aObj is ObjType
      ''');
      expect(
        result,
        true,
      );
    });
  });
}
