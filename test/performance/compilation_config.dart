import 'package:hetu_script/hetu_script.dart';

const _source = r'''
const answer = 6 * 7

/// Return the current result.
function run(n) {
  var result = 0
  var i = 0
  while (i < n) {
    assert(answer == 42, 'unexpected answer')
    result += answer
    ++i
  }
  return result
}

function failAssertion() {
  assert(false, 'expected assertion failure')
  return 1
}
''';

final _scenarios = <String, HetuConfig Function()>{
  'default': () => HetuConfig(normalizeImportPath: false),
  'constant_expression': () => HetuConfig(
        normalizeImportPath: false,
        doStaticAnalysis: true,
        computeConstantExpression: true,
      ),
  'no_assertion': () => HetuConfig(
        normalizeImportPath: false,
        removeAssertion: true,
      ),
  'no_line_info': () => HetuConfig(
        normalizeImportPath: false,
        removeLineInfo: true,
      ),
  'no_documentation': () => HetuConfig(
        normalizeImportPath: false,
        removeDocumentation: true,
      ),
  'release': () => HetuConfig(
        normalizeImportPath: false,
        removeAssertion: true,
        removeLineInfo: true,
        removeDocumentation: true,
      ),
};

void main(List<String> args) {
  final selected = args.isEmpty ? _scenarios.keys : args.take(1);
  for (final name in selected) {
    final createConfig = _scenarios[name];
    if (createConfig == null) {
      throw ArgumentError.value(name, 'scenario', 'Unknown scenario');
    }
    _runScenario(name, createConfig);
  }
}

void _runScenario(String name, HetuConfig Function() createConfig) {
  final compileSamples = <int>[];
  var bytes =
      Hetu(config: createConfig()).compile(_source, isModuleEntryScript: true);
  for (var i = 0; i < 5; ++i) {
    final compiler = Hetu(config: createConfig());
    final stopwatch = Stopwatch()..start();
    bytes = compiler.compile(_source, isModuleEntryScript: true);
    stopwatch.stop();
    compileSamples.add(stopwatch.elapsedMicroseconds);
  }

  final hetu = Hetu(config: createConfig());
  hetu.init();
  hetu.loadBytecode(bytes: bytes, module: name);

  const iterations = 100000;
  final warmup = hetu.invoke('run', positionalArgs: [10000]);
  _checkResult(name, warmup, 10000 * 42);
  final runSamples = <int>[];
  for (var i = 0; i < 5; ++i) {
    final stopwatch = Stopwatch()..start();
    final result = hetu.invoke('run', positionalArgs: [iterations]);
    stopwatch.stop();
    _checkResult(name, result, iterations * 42);
    runSamples.add(stopwatch.elapsedMicroseconds);
  }

  var assertion = 'returned';
  int? errorLine;
  try {
    hetu.invoke('failAssertion');
  } on HTError catch (error) {
    assertion = 'threw';
    errorLine = error.line;
  }

  compileSamples.sort();
  runSamples.sort();
  print(
    '$name: bytes=${bytes.length} '
    'compile_samples_us=$compileSamples '
    'compile_median_us=${compileSamples[compileSamples.length ~/ 2]} '
    'run_samples_us=$runSamples '
    'run_median_us=${runSamples[runSamples.length ~/ 2]} '
    'assertion=$assertion assertion_error_line=$errorLine '
    'static_analysis=${hetu.config.doStaticAnalysis} '
    'constant_expression=${hetu.config.computeConstantExpression}',
  );
}

void _checkResult(String name, dynamic result, int expected) {
  if (result is Future || result != expected) {
    throw StateError('$name returned $result, expected $expected');
  }
}
