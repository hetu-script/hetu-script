import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

Hetu _createHetu() {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init();
  return hetu;
}

Iterable<dynamic> _values(bool useMap) {
  final entries = [
    {'kind': 'attack'},
    {'kind': 'defense'},
  ];
  return useMap
      ? {for (final entry in entries) entry['kind']: entry}.values
      : entries;
}

void main() {
  test('Map.values where callback without captured variables', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function countEntries(values) {
        final matches = values.where((entry) {
          return entry.kind != null
        })
        return matches.length
      }
    ''');

    expect(hetu.invoke('countEntries', positionalArgs: [_values(true)]), 2);
  });

  test('List.where callback can read a captured variable', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function countKind(values, kind) {
        final matches = values.where((entry) {
          return entry.kind == kind
        })
        return matches.length
      }
    ''');

    expect(hetu.invoke('countKind', positionalArgs: [_values(false), 'attack']),
        1);
  });

  test('Map.values where callback can read a captured variable', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function countKind(values, kind) {
        final matches = values.where((entry) {
          return entry.kind == kind
        })
        return matches.length
      }
    ''');

    expect(
        hetu.invoke('countKind', positionalArgs: [_values(true), 'attack']), 1);
  });

  test('nested external Map.values callback can read a captured variable', () {
    final hetu = _createHetu();
    hetu.eval('var game');
    hetu.assign('game', {
      'passives': {
        'a': {'kind': 'attack'},
        'b': {'kind': 'defense'},
      }
    });
    hetu.eval(r'''
      function countKind(kind) {
        final matches = game.passives.values.where((entry) {
          return entry.kind == kind
        })
        return matches.length
      }
    ''');

    expect(hetu.invoke('countKind', positionalArgs: ['attack']), 1);
  });
}
