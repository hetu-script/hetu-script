import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
      processError: true,
    ),
  );
  hetu.init();

  group('throw -', () {
    test('throw string message', () {
      expect(
        () => hetu.eval(r''' throw 'something went wrong' '''),
        throwsA(isA<HTError>()),
      );
    });

    test('throw with expression', () {
      expect(
        () => hetu.eval(r'''
          var i = 42
          throw 'i is ${i}!'
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('throw null value', () {
      expect(
        () => hetu.eval(r''' throw null '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('assert -', () {
    test('assert failure throws', () {
      expect(
        () => hetu.eval(r''' assert(1 > 5) '''),
        throwsA(isA<HTError>()),
      );
    });

    test('assert success does not throw', () {
      final result = hetu.eval(r'''
        assert(5 > 1)
        42
      ''');
      expect(result, 42);
    });
  });

  group('undefined variable -', () {
    test('access undeclared variable throws', () {
      expect(
        () => hetu.eval(r''' undefinedVar '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('immutable -', () {
    test('reassign final variable throws', () {
      expect(
        () => hetu.eval(r'''
          final a = 42
          a = 100
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('reassign late variable throws', () {
      expect(
        () => hetu.eval(r'''
          late a
          a = 42
          a = 100
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('late initialization -', () {
    test('access unassigned late variable throws', () {
      expect(
        () => hetu.eval(r'''
          late a
          print(a)
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('late variable works after assignment', () {
      final result = hetu.eval(r'''
        late a
        a = 42
        a
      ''');
      expect(result, 42);
    });
  });

  group('arity -', () {
    test('wrong number of positional arguments throws', () {
      expect(
        () => hetu.eval(r'''
          function add(a, b) { return a + b }
          add(1)
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('too many arguments throws', () {
      expect(
        () => hetu.eval(r'''
          function add(a, b) { return a + b }
          add(1, 2, 3)
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('out of range -', () {
    test('list index out of bounds throws', () {
      expect(
        () => hetu.eval(r'''
          var list = [1, 2, 3]
          var item = list[10]
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('negative list index throws', () {
      expect(
        () => hetu.eval(r'''
          var list = [1, 2, 3]
          list[-1]
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('not callable -', () {
    test('calling non-function value throws', () {
      expect(
        () => hetu.eval(r'''
          var a = 42
          a()
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('calling null throws', () {
      expect(
        () => hetu.eval(r'''
          var a
          a()
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('undefined member -', () {
    test('accessing non-existent class member returns null', () {
      final result = hetu.eval(r'''
        class A {
          var name = 'test'
        }
        var a = A()
        a.nonExistent
      ''');
      expect(result, null);
    });
  });

  group('type cast -', () {
    test('invalid type cast throws', () {
      expect(
        () => hetu.eval(r'''
          class A { var name = 'A' }
          class B { var name = 'B' }
          var a = A()
          a as B
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('not spreadable -', () {
    test('spreading non-iterable non-struct throws', () {
      expect(
        () => hetu.eval(r'''
          var a = 42
          var list = [...a]
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('error propagation -', () {
    test('error propagates through nested function calls', () {
      expect(
        () => hetu.eval(r'''
          function inner() {
            throw 'inner error'
          }
          function outer() {
            inner()
          }
          outer()
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });
}
