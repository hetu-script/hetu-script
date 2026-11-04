import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('global aliases -', () {
    test('globalThis refers to the global namespace', () {
      final result = hetu.eval(r'''
        globalThis.Math.pow(2, 10)
      ''');
      expect(result, 1024);
    });

    test('NaN and Infinity constants', () {
      final result = hetu.eval(r'''
        [NaN.isNaN, Infinity == float.infinity, Infinity > float.maxFinite]
      ''');
      expect(result, [true, true, true]);
    });

    test('isNaN and isFinite global functions', () {
      final result = hetu.eval(r'''
        [isNaN(NaN), isNaN(1), isFinite(1), isFinite(Infinity)]
      ''');
      expect(result, [true, false, true, false]);
    });
  });

  group('List aliases -', () {
    test('push and pop', () {
      final result = hetu.eval(r'''
        var l = [1, 2]
        l.push(3)
        var lengthAfterPush = l.length
        var popped = l.pop()
        [lengthAfterPush, popped, l.length]
      ''');
      expect(result, [3, 3, 2]);
    });

    test('shift and unshift', () {
      final result = hetu.eval(r'''
        var l = [2, 3]
        l.unshift(1)
        var first = l.shift()
        [first, l]
      ''');
      expect(result, [
        1,
        [2, 3]
      ]);
    });

    test('slice is equivalent to sublist', () {
      final result = hetu.eval(r'''
        var l = [0, 1, 2, 3, 4]
        [l.slice(1, 3), l.slice(2)]
      ''');
      expect(result, [
        [1, 2],
        [2, 3, 4]
      ]);
    });

    test('findIndex and findLastIndex', () {
      final result = hetu.eval(r'''
        var l = [1, 2, 3, 2]
        [
          l.findIndex((n) => n % 2 == 0),
          l.findLastIndex((n) => n % 2 == 0),
          l.findIndex((n) => n > 10)
        ]
      ''');
      expect(result, [1, 3, -1]);
    });
  });

  group('Iterable aliases -', () {
    test('filter is equivalent to where', () {
      final result = hetu.eval(r'''
        [1, 2, 3, 4].filter((n) => n % 2 == 0).toList()
      ''');
      expect(result, [2, 4]);
    });

    test('some and includes', () {
      final result = hetu.eval(r'''
        var l = [1, 2, 3]
        [l.some((n) => n > 2), l.some((n) => n > 10), l.includes(2), l.includes(9)]
      ''');
      expect(result, [true, false, true, false]);
    });

    test('find and findLast return null when no match', () {
      final result = hetu.eval(r'''
        var l = [1, 2, 4, 3]
        [l.find((n) => n % 2 == 0), l.findLast((n) => n % 2 == 0), l.find((n) => n > 10)]
      ''');
      expect(result, [2, 4, null]);
    });

    test('flatMap is equivalent to expand', () {
      final result = hetu.eval(r'''
        [1, 2].flatMap((n) => [n, n * 10]).toList()
      ''');
      expect(result, [1, 10, 2, 20]);
    });
  });

  group('String aliases -', () {
    test('padStart and padEnd', () {
      final result = hetu.eval(r'''
        ['7'.padStart(3, '0'), '7'.padEnd(3, '0')]
      ''');
      expect(result, ['007', '700']);
    });

    test('trimStart and trimEnd', () {
      final result = hetu.eval(r'''
        ['  x  '.trimStart(), '  x  '.trimEnd()]
      ''');
      expect(result, ['x  ', '  x']);
    });

    test('charCodeAt, includes and replace', () {
      final result = hetu.eval(r'''
        ['A'.charCodeAt(0), 'hello'.includes('ell'), 'hello'.includes('z'), 'aaa'.replace('a', 'b')]
      ''');
      expect(result, [65, true, false, 'baa']);
    });
  });

  group('Number aliases -', () {
    test('toExponential and toPrecision match their Dart counterparts', () {
      final result = hetu.eval(r'''
        var a = 1234.5
        [a.toExponential(2) == a.toStringAsExponential(2), a.toPrecision(4) == a.toStringAsPrecision(4)]
      ''');
      expect(result, [true, true]);
    });
  });

  group('Math aliases -', () {
    test('uppercase constants', () {
      final result = hetu.eval(r'''
        Math.PI == Math.pi && Math.E == Math.e &&
        Math.LN2 == Math.ln2 && Math.LN10 == Math.ln10 &&
        Math.LOG2E == Math.log2e && Math.LOG10E == Math.log10e &&
        Math.SQRT2 == Math.sqrt2 && Math.SQRT1_2 == Math.sqrt1_2
      ''');
      expect(result, true);
    });

    test('static wrappers of instance methods', () {
      final result = hetu.eval(r'''
        [Math.abs(-3), Math.floor(1.9), Math.ceil(1.1), Math.round(1.5), Math.trunc(-1.9), Math.sign(-5)]
      ''');
      expect(result, [3, 1, 2, 2, -1, -1]);
    });

    test('min and max accept variadic arguments', () {
      final result = hetu.eval(r'''
        [Math.min(3, 1, 2), Math.max(3, 1, 2), Math.min(5), Math.min(10, 20), Math.max(10, 20)]
      ''');
      expect(result, [1, 3, 5, 10, 20]);
    });

    test('min and max ignore null and propagate NaN', () {
      final result = hetu.eval(r'''
        [Math.min(null, 5), Math.max(null, 5), Math.min(1, NaN, 3).isNaN]
      ''');
      expect(result, [5, 5, true]);
    });

    test('min and max with no arguments return infinities', () {
      final result = hetu.eval(r'''
        [Math.min(), Math.max()]
      ''');
      expect(result, [double.infinity, double.negativeInfinity]);
    });
  });

  group('Map and Set aliases -', () {
    test('Map.has and Map.size', () {
      final result = hetu.eval(r'''
        var m = Map()
        m['x'] = 1
        [m.has('x'), m.has('y'), m.size]
      ''');
      expect(result, [true, false, 1]);
    });

    test('Set.has and Set.size', () {
      final result = hetu.eval(r'''
        var s = Set([1, 2])
        [s.has(1), s.has(3), s.size]
      ''');
      expect(result, [true, false, 2]);
    });
  });

  group('Object aliases -', () {
    test('Object.hasOwn', () {
      final result = hetu.eval(r'''
        var o = {a: 1}
        [Object.hasOwn(o, 'a'), Object.hasOwn(o, 'b')]
      ''');
      expect(result, [true, false]);
    });
  });

  group('console aliases -', () {
    test('console.warn and console.warning both work', () {
      expect(() {
        hetu.eval(r'''
          console.warn('warn message')
          console.warning('warning message')
        ''');
      }, returnsNormally);
    });
  });

  group('type alias static access -', () {
    test('built-in aliases can access static members', () {
      final result = hetu.eval(r'''
        [str.parse(42), int.parse('42'), double.parse('3.14')]
      ''');
      expect(result, ['42', 42, 3.14]);
    });

    test('user-defined alias can construct and access static members', () {
      final result = hetu.eval(r'''
        type MyList = List
        var l = MyList()
        l.add(1)
        [l.length, l is List]
      ''');
      expect(result, [1, true]);
    });

    test('chained aliases resolve to the same class', () {
      final result = hetu.eval(r'''
        type A = List
        type B = A
        var l = B()
        l is List
      ''');
      expect(result, true);
    });

    test('type annotation through alias still works', () {
      final result = hetu.eval(r'''
        type MyListForAnnotation = List
        var l: MyListForAnnotation = [1, 2]
        l.length
      ''');
      expect(result, 2);
    });

    test('alias of a not yet declared type falls back to type-only behavior', () {
      expect(() {
        hetu.eval(r'''
          type Forward = NotDeclaredYet
          var x = 1
        ''');
      }, returnsNormally);
    });

    test('generic and nullable aliases keep type-only behavior', () {
      final result = hetu.eval(r'''
        type NullableList = List?
        var l: NullableList = null
        l == null
      ''');
      expect(result, true);
    });

    test('Array alias constructs lists and works in type annotations', () {
      final result = hetu.eval(r'''
        var l = Array()
        l.push(1)
        var l2: Array = [1, 2]
        [l.length, l is List, l2.length, l2 is List]
      ''');
      expect(result, [1, true, 2, true]);
    });

    test('capitalized type names and lowercase aliases are interchangeable', () {
      final result = hetu.eval(r'''
        var s: string = 'hello'
        var s2: String = s
        var i: int = 42
        var i2: integer = i
        var f: float = 1.5
        var f2: Float = f
        var b: bool = true
        var n: num = 3.14
        [
          s2.length, i2, f2, b, n,
          String.fromCharCode(65), string.parse(42),
          Number.isNaN(NaN), number.parse('2.5'),
          Integer.parse('7'), integer.parse('8'),
          Bool.parse('true')
        ]
      ''');
      expect(result,
          [5, 42, 1.5, true, 3.14, 'A', '42', true, 2.5, 7, 8, true]);
    });
  });

  group('Promise aliases -', () {
    test('Promise.value and Promise.wait', () {
      final result = hetu.eval(r'''
        var f = Promise.value(7)
        var w = Promise.wait([Promise.value(1), Promise.value(2)])
        [f is Future, w is Future]
      ''');
      expect(result, [true, true]);
    });

    test('Promise.resolve and Promise.all', () {
      final result = hetu.eval(r'''
        var f = Promise.resolve(7)
        var w = Promise.all([Promise.resolve(1), Promise.resolve(2)])
        [f is Future, w is Future]
      ''');
      expect(result, [true, true]);
    });
  });

  group('Number static aliases -', () {
    test('Number.isNaN and Number.isFinite', () {
      final result = hetu.eval(r'''
        [Number.isNaN(NaN), Number.isNaN(1), Number.isFinite(1), Number.isFinite(Infinity)]
      ''');
      expect(result, [true, false, true, false]);
    });
  });

  group('P1: forEach -', () {
    test('Iterable.forEach iterates all elements', () {
      final result = hetu.eval(r'''
        var sum = 0
        [1, 2, 3].forEach((n) => sum += n)
        sum
      ''');
      expect(result, 6);
    });

    test('Map.forEach passes key and value', () {
      final result = hetu.eval(r'''
        var m = Map()
        m['a'] = 1
        m['b'] = 2
        var pairs = []
        m.forEach((k, v) => pairs.add([k, v]))
        pairs
      ''');
      expect(result, [
        ['a', 1],
        ['b', 2]
      ]);
    });
  });

  group('P1: Map methods -', () {
    test('Map.get and Map.set', () {
      final result = hetu.eval(r'''
        var m = Map()
        m.set('a', 1)
        [m.get('a'), m.get('b')]
      ''');
      expect(result, [1, null]);
    });

    test('Map.entries returns MapEntry iterable', () {
      final result = hetu.eval(r'''
        var m = Map()
        m['a'] = 1
        m['b'] = 2
        var entries = m.entries.toList()
        [entries.length, entries[0].key, entries[0].value, entries[1].key]
      ''');
      expect(result, [2, 'a', 1, 'b']);
    });
  });

  group('P1: Promise methods -', () {
    test('Promise.reject with catch handler', () {
      final result = hetu.eval(r'''
        var f = Promise.reject('x')
        var g = f.catch((e) => e)
        g is Future
      ''');
      expect(result, true);
    });

    test('catchError, finally and whenComplete return futures', () {
      final result = hetu.eval(r'''
        var f = Promise.value(1)
        var a = f.catchError((e) => 0)
        var b = f.finally(() => 0)
        var c = f.whenComplete(() => 0)
        [a is Future, b is Future, c is Future]
      ''');
      expect(result, [true, true, true]);
    });
  });

  group('P1: Math.atan2 -', () {
    test('atan2 matches atan for the first quadrant', () {
      final result = hetu.eval(r'''
        Math.atan2(1, 1) == Math.atan(1)
      ''');
      expect(result, true);
    });
  });

  group('P1: String methods -', () {
    test('charAt, repeat and String.fromCharCode', () {
      final result = hetu.eval(r'''
        ['abc'.charAt(1), 'ab'.repeat(3), String.fromCharCode(65)]
      ''');
      expect(result, ['b', 'ababab', 'A']);
    });
  });

  group('P1: Object entries -', () {
    test('Object.entries returns a list of MapEntry', () {
      final result = hetu.eval(r'''
        var o = {a: 1, b: 2}
        var entries = Object.entries(o)
        [entries.length, entries[0].key, entries[0].value]
      ''');
      expect(result, [2, 'a', 1]);
    });

    test('Object.fromEntries accepts MapEntry and pairs', () {
      final result = hetu.eval(r'''
        var o = Object.fromEntries([MapEntry('a', 1), ['b', 2]])
        [o['a'], o['b']]
      ''');
      expect(result, [1, 2]);
    });
  });

  group('delete as member name -', () {
    test('Map.delete and Set.delete', () {
      final result = hetu.eval(r'''
        var m = Map()
        m['x'] = 1
        var removed = m.delete('x')
        var s = Set([1, 2])
        var deleted = s.delete(1)
        [removed, m.size, deleted, s.size, s.delete(9)]
      ''');
      expect(result, [1, 0, true, 1, false]);
    });

    test('delete statement still works alongside member calls', () {
      final result = hetu.eval(r'''
        var obj = {a: 1}
        delete obj.a
        var m = Map()
        m['k'] = 2
        delete m['k']
        [obj.containsKey('a'), m.size]
      ''');
      expect(result, [false, 0]);
    });
  });
}
