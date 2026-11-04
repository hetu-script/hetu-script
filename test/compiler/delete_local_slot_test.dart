import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

Hetu _createHetu() {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init();
  return hetu;
}

void main() {
  test('delete subscript resolves an optimized local map', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function removeEntry() {
        final sources = {'a': 1}
        delete sources['a']
        return sources.isEmpty
      }
    ''');

    expect(hetu.invoke('removeEntry'), isTrue);
  });

  test('delete subscript resolves local object and key inside loops', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function removeEntries(raw) {
        for (final dataId in raw.keys.toList()) {
          final sources = raw[dataId]
          for (final sourceKey in sources.keys.toList()) {
            delete sources[sourceKey]
          }
          if (sources.isEmpty) delete raw[dataId]
        }
        return raw.isEmpty
      }
    ''');

    final result = hetu.invoke('removeEntries', positionalArgs: [
      {
        'first': {'a': 1, 'b': 2},
        'second': {'c': 3},
      }
    ]);
    expect(result, isTrue);
  });
}
