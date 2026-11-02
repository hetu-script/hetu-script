import 'package:hetu_script/binding.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

int _zero() => 1;
int _sum2(int a, int b) => a + b;
int _sum4(int a, int b, int c, int d) => a + b + c + d;

class _Counter {
  int value = 0;

  int add(int amount) => value += amount;
  int addBoth(int a, int b) => value += a + b;
}

class _CounterBinding extends HTExternalClass {
  _CounterBinding() : super('Counter');

  @override
  dynamic memberGet(
    String id, {
    String? from,
    bool isRecursive = false,
    bool ignoreUndefined = false,
  }) {
    if (id == 'Counter') {
      return ({positionalArgs, namedArgs}) => _Counter();
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }

  @override
  dynamic instanceMemberGet(
    dynamic instance,
    String id, {
    bool ignoreUndefined = false,
  }) {
    if (id == 'add') {
      return (_Counter object, int amount) => object.add(amount);
    }
    if (id == 'addBoth') {
      return (_Counter object, int a, int b) => object.addBoth(a, b);
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }
}

void main() {
  test('raw positional calls support common arities and receivers', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(
      externalFunctions: {'zero': _zero, 'sum2': _sum2, 'sum4': _sum4},
      externalClasses: [_CounterBinding()],
      externalTypeReflections: [
        (object) => object is _Counter ? 'Counter' : null,
      ],
    );

    final result = hetu.eval(r'''
      external function zero
      external function sum2(a, b)
      external function sum4(a, b, c, d)
      external class Counter {
        constructor()
        function add(amount: int) -> int
        function addBoth(a: int, b: int) -> int
      }
      final counter = Counter()
      [zero(), sum2(1, 2), sum4(1, 2, 3, 4), counter.add(1), counter.addBoth(2, 3)]
    ''');

    expect(result, [1, 3, 10, 1, 6]);
  });
}
