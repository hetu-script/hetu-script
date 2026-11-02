import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

void main() {
  test('simple functions preserve optional and omitted parameters', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init();
    final result = hetu.eval(r'''
      function add(a, [b = 2]) {
        return a + b
      }
      function second(_, value) {
        return value
      }
      [add(1), add(1, 3), second(1, 2)]
    ''');

    expect(result, [3, 4, 2]);
  });

  test('simple methods preserve this and closures', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init();
    final result = hetu.eval(r'''
      class Counter {
        var value = 1
        function add(amount) {
          value += amount
          return value
        }
      }
      function makeAdder(x) {
        return (y) => x + y
      }
      final counter = Counter()
      final addTwo = makeAdder(2)
      [counter.add(2), counter.add(3), addTwo(4)]
    ''');

    expect(result, [3, 6, 6]);
  });
}
