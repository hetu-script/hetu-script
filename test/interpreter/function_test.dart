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
    test('arrow function single-line body', () {
      final result = hetu.eval(r'''
        var double = (x) => x * 2
        double(21)
      ''');
      expect(result, 42);
    });

    test('optional named parameters with defaults', () {
      final result = hetu.eval(r'''
        function optFunc(a, b, {c: number = 3, d: number = 5}) {
          return a + b + c + d
        }
        optFunc(1, 2, d: 7)
      ''');
      expect(result, 1 + 2 + 3 + 7);
    });

    test('IIFE - immediately invoked function', () {
      final result = hetu.eval(r'''
        (function (x) { return x * x })(7)
      ''');
      expect(result, 49);
    });

    test('recursive function', () {
      final result = hetu.eval(r'''
        function factorial(n) {
          if (n <= 1) {
            return 1
          }
          return n * factorial(n - 1)
        }
        factorial(5)
      ''');
      expect(result, 120);
    });

    test('function identity - distinct closures are different', () {
      final result = hetu.eval(r'''
        function makeCounter() {
          var count = 0
          return () { return ++count }
        }
        var c1 = makeCounter()
        var c2 = makeCounter()
        c1()
        c1()
        c2()
        c1()  // c1 has its own counter
      ''');
      expect(result, 3);
    });

    test('closure captures outer variable', () {
      final result = hetu.eval(r'''
        function makeAdder(x) {
          return (y) => x + y
        }
        var add5 = makeAdder(5)
        add5(10)
      ''');
      expect(result, 15);
    });

    test('variadic parameters', () {
      final result = hetu.eval(r'''
        function sumAll(...args) {
          var total = 0
          for (var item in args) {
            total += item
          }
          return total
        }
        sumAll(1, 2, 3, 4, 5)
      ''');
      expect(result, 15);
    });
  });

  group('functions existing -', () {
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
        function namedArgFun({a: number, b: number = 2, c: number}) {
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

    test('Function.bind() changes this context', () {
      final result = hetu.eval(r'''
        final bindObj1 = { name: 'Alice', greeting: '' }
        function bindGreet() {
          return this.name
        }
        bindObj1.greeting = bindGreet
        bindObj1.greeting()
      ''');
      expect(result, 'Alice');
    });
  });
}
