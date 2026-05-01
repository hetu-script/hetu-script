import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

Hetu createHetu() {
  final hetu = Hetu(
    config: HetuConfig(printPerformanceStatistics: false),
  );
  hetu.init(
    externalFunctions: {
      'fetch42': () =>
          Future.delayed(const Duration(milliseconds: 100)).then((_) => 42),
      'fetchString': () => Future.delayed(const Duration(milliseconds: 100))
          .then((_) => 'hello'),
    },
  );
  return hetu;
}

Future<T> resolve<T>(dynamic value) async {
  while (value is Future) {
    value = await value;
  }
  return value as T;
}

void main() {
  group('async/await -', () {
    test('await on non-Future int', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<int> async {
          var x = 10;
          var y = await x;
          return y;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 10);
    });

    test('await on non-Future string', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<string> async {
          var x = 'hello world';
          var y = await x;
          return y;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 'hello world');
    });

    test('await on non-Future bool', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<bool> async {
          var x = true;
          var y = await x;
          return y;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), true);
    });

    test('await on external Future', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function test() -> Future<int> async {
          var result = await fetch42();
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 42);
    });

    test('await on Future.value', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<int> async {
          var result = await Future.value(77);
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 77);
    });

    test('async function without await', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<int> async {
          return 99;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 99);
    });

    test('multiple sequential awaits', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        external function fetchString() -> Future<string>;
        function test() -> Future<string> async {
          var a = await fetch42();
          var b = await fetchString();
          return '' + a.toString() + '-' + b;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), '42-hello');
    });

    test('nested async function calls', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function inner() -> Future<int> async {
          return await fetch42() + 10;
        }
        function test() -> Future<int> async {
          var result = await inner();
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 52);
    });

    test('await in if branch', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function test(flag: bool) -> Future<int> async {
          if (flag) {
            var a = await fetch42();
            return a + 1;
          } else {
            var b = await fetch42();
            return b + 2;
          }
        }
      ''');
      expect(await resolve(hetu.invoke('test', positionalArgs: [true])), 43);
    });

    test('await in else branch', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function test(flag: bool) -> Future<int> async {
          if (flag) {
            var a = await fetch42();
            return a + 1;
          } else {
            var b = await fetch42();
            return b + 2;
          }
        }
      ''');
      expect(await resolve(hetu.invoke('test', positionalArgs: [false])), 44);
    });

    test('await in arithmetic expression', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function test() -> Future<int> async {
          var result = await fetch42() * 2 + await fetch42();
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 126);
    });

    test('Future.wait', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<int> async {
          var results = await Future.wait([Future.value(10), Future.value(20), Future.value(30)]);
          return results[0] + results[1] + results[2];
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 60);
    });

    test('await on non-async function returning Future', () async {
      final hetu = createHetu();
      hetu.eval('''
        external function fetch42() -> Future<int>;
        function syncFunc() -> Future<int> {
          return fetch42();
        }
        function test() -> Future<int> async {
          var result = await syncFunc();
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), 42);
    });

    test('chained .then() on Future', () async {
      final hetu = createHetu();
      hetu.eval('''
        function test() -> Future<string> async {
          var result = await Future.value(42).then((val) {
            return val.toString() + '-then';
          });
          return result;
        }
      ''');
      expect(await resolve(hetu.invoke('test')), '42-then');
    });
  });
}
