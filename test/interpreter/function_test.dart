import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('functions -', () {
    test('nested & anonymous', () {
      final result = hetu.eval(r'''
        function literalFunction(func) {
          var i = 42
          function nested() {
            i = i + 1
            return (func(i))
          }
          return nested
        }
        var func = literalFunction( function (n) { return n * n } )
        func()
        func()
      ''');
      expect(
        result,
        1936,
      );
    });
    test('closure in loop', () {
      final result = hetu.eval(r'''
        var list = [];
        var builders = [];
        function build(i, add) {
          builders.add(function () {
            add(i);
          });
        }
        for (var i = 0; i < 5; ++i) {
          build(i, function (n)  {
            list.add(n);
          });
        }
        for (var func in builders) {
          func();
        }
        list[1]
      ''');
      expect(
        result,
        1,
      );
    });
    test('named args', () {
      final result = hetu.eval(r'''
        function namedArgFun({a: num, b: num = 2, c: num}) {
          return a * b
        }
        namedArgFun(a: 21)
      ''');
      expect(
        result,
        42,
      );
    });
    test('function.apply()', () {
      final result = hetu.eval(r'''
        final obj = {
          name: 'jimmy'
        }
        final greeting = () {
          return this.name
        }
        greeting.apply(obj)
      ''');
      expect(
        result,
        'jimmy',
      );
    });
  });
}
