import 'package:hetu_script/hetu_script.dart';

Future<dynamic> _invoke(Hetu hetu, int n) async {
  dynamic result = hetu.invoke('fib', positionalArgs: [n]);
  while (result is Future) {
    result = await result;
  }
  return result;
}

Future<void> main() async {
  final hetu = Hetu(
    sourceContext: HTOverlayContext(),
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(
      normalizeImportPath: false,
      allowImplicitNullToZeroConversion: true,
      printPerformanceStatistics: true,
      showHetuStackTrace: true,
    ),
  );
  hetu.init();
  hetu.eval(r'''
    fun fib(n) {
      if (n <= 1) {
        return n
      } else {
        return fib(n - 1) + fib(n - 2)
      }
    }
  ''');

  final warmup = await _invoke(hetu, 20);
  if (warmup != 6765) {
    throw StateError('fib warmup returned $warmup, expected 6765');
  }

  final samples = <int>[];
  for (var i = 0; i < 5; ++i) {
    final stopwatch = Stopwatch()..start();
    final result = await _invoke(hetu, 30);
    stopwatch.stop();
    if (result != 832040) {
      throw StateError('fib returned $result, expected 832040');
    }
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  print(
    'fib: n=30 samples_us=$samples median_us=$median checksum=832040',
  );
}
