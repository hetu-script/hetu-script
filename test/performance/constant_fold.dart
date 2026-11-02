import 'dart:math' as math;

import 'package:hetu_script/hetu_script.dart';

const _foldableSource = r'''
function run(n) {
  var result = 0;
  var i = 0;
  while (i < n) {
    result += 6 * 7 + 8 ~/ 2 + 9 % 4;
    result += (1 + 1 == 2 ? 1 : 0);
    result += (false && 1 ~/ 0 == 0 ? 100 : 2);
    result += (true || 1 ~/ 0 == 0 ? 3 : 100);
    result += (6 ?? 2);
    result += ('hetu' + 'script' == 'hetuscript' ? 1 : 0);
    result += ('value-${6 * 7}' == 'value-42' ? 1 : 0);
    ++i;
  }
  return result;
}
''';

const _dynamicSource = r'''
function run(n, a, b, c, d, e, f, flag, leftText, rightText) {
  var result = 0;
  var i = 0;
  while (i < n) {
    result += a * b + c ~/ d + e % f;
    result += (a + 1 == b ? 1 : 0);
    result += (flag && 1 ~/ 0 == 0 ? 100 : 2);
    result += (!flag || 1 ~/ 0 == 0 ? 3 : 100);
    result += (a ?? 2);
    result += (leftText + rightText == 'hetuscript' ? 1 : 0);
    result += ('value-${a * b}' == 'value-42' ? 1 : 0);
    ++i;
  }
  return result;
}
''';

final _scenarios = <String, (String, List<dynamic>)>{
  'foldable': (_foldableSource, const []),
  'dynamic': (
    _dynamicSource,
    const [6, 7, 8, 2, 9, 4, false, 'hetu', 'script'],
  ),
};

void main(List<String> args) {
  final selected = args.isEmpty ? _scenarios.keys : args.take(1);
  for (final name in selected) {
    final scenario = _scenarios[name];
    if (scenario == null) {
      throw ArgumentError.value(name, 'scenario', 'Unknown scenario');
    }
    _runScenario(name, source: scenario.$1, fixedArgs: scenario.$2);
  }
}

void _runScenario(
  String name, {
  required String source,
  required List<dynamic> fixedArgs,
}) {
  Hetu createCompiler() => Hetu(config: HetuConfig(normalizeImportPath: false));

  final compileSamples = <int>[];
  var bytes = createCompiler().compile(source);
  for (var i = 0; i < 5; ++i) {
    final compiler = createCompiler();
    final stopwatch = Stopwatch()..start();
    bytes = compiler.compile(source);
    stopwatch.stop();
    compileSamples.add(stopwatch.elapsedMicroseconds);
  }

  final hetu = createCompiler();
  hetu.init();
  hetu.loadBytecode(bytes: bytes, module: name);

  const iterations = 100000;
  final warmupIterations = math.min(iterations, 10000);
  final warmup = hetu.invoke(
    'run',
    positionalArgs: [warmupIterations, ...fixedArgs],
  );
  _checkResult(name, warmup, warmupIterations * 61);

  final runSamples = <int>[];
  for (var i = 0; i < 5; ++i) {
    final stopwatch = Stopwatch()..start();
    final result = hetu.invoke(
      'run',
      positionalArgs: [iterations, ...fixedArgs],
    );
    stopwatch.stop();
    _checkResult(name, result, iterations * 61);
    runSamples.add(stopwatch.elapsedMicroseconds);
  }

  compileSamples.sort();
  runSamples.sort();
  print(
    '$name: bytes=${bytes.length} iterations=$iterations '
    'compile_samples_us=$compileSamples '
    'compile_median_us=${compileSamples[compileSamples.length ~/ 2]} '
    'run_samples_us=$runSamples '
    'run_median_us=${runSamples[runSamples.length ~/ 2]} '
    'checksum=${iterations * 61}',
  );
}

void _checkResult(String name, dynamic result, int expected) {
  if (result is Future || result != expected) {
    throw StateError('$name returned $result, expected $expected');
  }
}
