import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

void main() {
  test(
      'script parameter binding preserves omission, closures and field initialization',
      () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init();
    final result = hetu.eval(r'''
      function second(_, value) {
        return value
      }
      function makeAdder(x) {
        return (y) => x + y
      }
      class Box {
        var value
        constructor(this.value) {}
      }
      final addTwo = makeAdder(2)
      [second(1, 2), addTwo(3), Box(42).value]
    ''');

    expect(result, [2, 5, 42]);
  });

  test('external parameter binding preserves omitted and named arguments', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(externalFunctions: {
      'collect': ({positionalArgs, namedArgs}) => [
            positionalArgs[0],
            positionalArgs[1],
            namedArgs['flag'],
          ],
    });
    final result = hetu.eval(r'''
      external function collect(_, value, {flag = false})
      collect(1, 2, flag: true)
    ''');

    expect(result, [1, 2, true]);
  });
}
