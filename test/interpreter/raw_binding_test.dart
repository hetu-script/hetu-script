import 'package:hetu_script/binding.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

int _rawAdd(int left, int right, {int offset = 0}) => left + right + offset;

class _RawCounter {
  int value = 0;

  int add(int amount, {int offset = 0}) {
    value += amount + offset;
    return value;
  }
}

class _RawCounterBinding extends HTExternalClass {
  _RawCounterBinding() : super('RawCounter');

  @override
  dynamic memberGet(
    String id, {
    String? from,
    bool isRecursive = false,
    bool ignoreUndefined = false,
  }) {
    if (id == 'RawCounter') {
      return ({positionalArgs, namedArgs}) => _RawCounter();
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
      return (_RawCounter object, int amount, {int offset = 0}) =>
          object.add(amount, offset: offset);
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }
}

void main() {
  test('raw functions preserve receiver order and named arguments', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(
      externalFunctions: {'rawAdd': _rawAdd},
      externalClasses: [_RawCounterBinding()],
      externalTypeReflections: [
        (object) => object is _RawCounter ? 'RawCounter' : null,
      ],
    );

    final result = hetu.eval(r'''
      external function rawAdd(left, right, {offset: int = 0})
      external class RawCounter {
        constructor()
        function add(amount: int, {offset: int = 0}) -> int
      }
      final counter = RawCounter()
      [
        rawAdd(1, 2, offset: 3),
        rawAdd(4, 5),
        counter.add(2, offset: 3),
        counter.add(4),
      ]
    ''');

    expect(result, [6, 9, 5, 9]);
  });
}
