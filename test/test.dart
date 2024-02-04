import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
        // printPerformanceStatistics: true,
        ),
    sourceContext: sourceContext,
  );
  hetu.init(
    locale: HTLocaleSimplifiedChinese(),
  );

  final r = ('sd', 1234);

  hetu.eval(
    r'''
  fun getRecord(value) {
    print(value)
    print(typeof value)
  }
''',
    invoke: 'getRecord',
    positionalArgs: [r],
  );
}
