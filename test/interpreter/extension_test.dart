import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    config: HetuConfig(
      normalizeImportPath: false,
    ),
  );
  hetu.init();

  group('extension on namespace -', () {
    test('extend an imported namespace from entry script', () {
      sourceContext.addResource('ext_a.ht', HTSource('''
    namespace Calc {
      fun base() {
        return 40
      }
    }
  '''));

      final result = hetu.eval(r'''
    import 'ext_a.ht'

    extension namespace Calc {
      fun extra() {
        return 2
      }
    }

    Calc.base() + Calc.extra()
  ''');

      expect(result, 42);
    });

    test('extend an imported namespace from another module file', () {
      sourceContext.addResource('ext_b_base.ht', HTSource('''
    namespace Greeter {
      fun hello() {
        return 'hello'
      }
    }
  '''));
      sourceContext.addResource('ext_b_ext.ht', HTSource('''
    import 'ext_b_base.ht'

    extension namespace Greeter {
      fun world() {
        return 'world'
      }
    }
  '''));

      final result = hetu.eval(r'''
    import 'ext_b_base.ht'
    import 'ext_b_ext.ht'

    '${Greeter.hello()} ${Greeter.world()}'
  ''');

      expect(result, 'hello world');
    });

    test('extension mutates the shared namespace object', () {
      sourceContext.addResource('ext_c.ht', HTSource('''
    namespace Shared {
      fun one() {
        return 1
      }
    }
  '''));
      sourceContext.addResource('ext_c_ext.ht', HTSource('''
    import 'ext_c.ht'

    extension namespace Shared {
      fun two() {
        return 2
      }
    }
  '''));

      // the entry script imports the original file by alias,
      // the extension made by another file is visible through it,
      // because both imports refer to the same namespace object
      final result = hetu.eval(r'''
    import 'ext_c.ht' as orig
    import 'ext_c_ext.ht'

    orig.Shared.one() + orig.Shared.two()
  ''');

      expect(result, 3);
    });

    test('member conflict in extension throws', () {
      sourceContext.addResource('ext_d.ht', HTSource('''
    namespace Conflict {
      fun existing() {
        return 1
      }
    }
  '''));

      expect(
        () => hetu.eval(r'''
    import 'ext_d.ht'

    extension namespace Conflict {
      fun existing() {
        return 2
      }
    }
  '''),
        throwsA(isA<HTError>()),
      );
    });

    test('extending an undefined target throws', () {
      expect(
        () => hetu.eval(r'''
    extension namespace NoSuchNamespace {
      fun whatever() {
        return 1
      }
    }
  '''),
        throwsA(isA<HTError>()),
      );
    });

    test('extending a non-namespace target throws', () {
      sourceContext.addResource('ext_e.ht', HTSource('''
    class NotANamespace {
      fun method() {
        return 1
      }
    }
  '''));

      expect(
        () => hetu.eval(r'''
    import 'ext_e.ht'

    extension namespace NotANamespace {
      fun whatever() {
        return 1
      }
    }
  '''),
        throwsA(isA<HTError>()),
      );
    });

    test('non-function member in extension block is rejected', () {
      sourceContext.addResource('ext_f.ht', HTSource('''
    namespace OnlyFunctions {
      fun existing() {
        return 1
      }
    }
  '''));

      expect(
        () => hetu.eval(r'''
    import 'ext_f.ht'

    extension namespace OnlyFunctions {
      var notAFunction = 42
    }
  '''),
        throwsA(isA<HTError>()),
      );
    });
  });
}
