import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

Hetu _createHetu(int displayLimit) {
  return Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      showHetuStackTrace: true,
      stackTraceDisplayCountLimit: displayLimit,
    ),
  )..init();
}

void main() {
  test('nested errors include the throwing function and preserve stack order',
      () {
    final hetu = _createHetu(-1);
    Object? error;
    try {
      hetu.eval(r'''
        function inner() {
          throw 'boom'
        }
        function outer({value = 1}) {
          inner()
        }
        outer()
      ''');
    } on HTError catch (caught) {
      error = caught;
    }

    expect(error, isA<HTError>());
    final extra = (error as HTError).extra;
    expect(extra, isNotNull);
    expect(extra, contains('inner ('));
    expect(extra, contains('outer ('));
    expect(extra!.indexOf('inner ('), lessThan(extra.indexOf('outer (')));
    expect(hetu.interpreter.stackTraceList, isEmpty);
  });

  test('stack display limit keeps the throwing function', () {
    final hetu = _createHetu(1);
    Object? error;
    try {
      hetu.eval(r'''
        function inner() {
          throw 'boom'
        }
        function outer() {
          inner()
        }
        outer()
      ''');
    } on HTError catch (caught) {
      error = caught;
    }

    final extra = (error as HTError).extra!;
    expect(extra, contains('inner ('));
    expect(extra, isNot(contains('outer (')));
    expect(extra, contains('other 1 messages'));
    expect(hetu.interpreter.stackTraceList, isEmpty);
  });
}
