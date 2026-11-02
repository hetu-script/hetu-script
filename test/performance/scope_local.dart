import 'dart:math' as math;

import 'package:hetu_script/hetu_script.dart';

const _source = r'''
final increment = (value) => value + 1
final dynamicBox = {value: 0}

function runLocal(n) {
  var result = 0
  var left = 1
  var right = 2
  var i = 0
  while (i < n) {
    result += left + right
    final temporary = left
    left = right
    right = temporary
    ++i
  }
  return result + left + right
}

function runUncapturedClosure(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = increment(result)
    ++i
  }
  return result
}

function runCapturedVariable(n) {
  var captured = 0
  final accumulate = (value) {
    captured += value
    return captured
  }
  var i = 0
  while (i < n) {
    accumulate(1)
    ++i
  }
  return captured
}

function runDynamicFallback(n) {
  dynamicBox.value = 0
  var i = 0
  while (i < n) {
    dynamicBox.value = dynamicBox.value + 1
    ++i
  }
  return dynamicBox.value
}
''';

final _scenarios = <String, (String, int)>{
  'local': ('runLocal', 100000),
  'uncaptured_closure': ('runUncapturedClosure', 100000),
  'captured_variable': ('runCapturedVariable', 100000),
  'dynamic_fallback': ('runDynamicFallback', 100000),
};

void main(List<String> args) {
  final selected = args.isEmpty ? _scenarios.keys : args.take(1);
  for (final name in selected) {
    final scenario = _scenarios[name];
    if (scenario == null) {
      throw ArgumentError.value(name, 'scenario', 'Unknown scenario');
    }
    _runScenario(name, functionName: scenario.$1, iterations: scenario.$2);
  }
}

void _runScenario(
  String name, {
  required String functionName,
  required int iterations,
}) {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init();
  hetu.eval(_source);

  final warmupIterations = math.min(iterations, 10000);
  final warmup = hetu.invoke(functionName, positionalArgs: [warmupIterations]);
  _checkResult(name, warmup, _expected(name, warmupIterations));

  final samples = <int>[];
  var checksum = 0;
  for (var i = 0; i < 5; ++i) {
    final stopwatch = Stopwatch()..start();
    final result = hetu.invoke(functionName, positionalArgs: [iterations]);
    stopwatch.stop();
    _checkResult(name, result, _expected(name, iterations));
    checksum = result as int;
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  print(
    '$name: iterations=$iterations samples_us=$samples median_us=$median '
    'us_per_iteration=${(median / iterations).toStringAsFixed(3)} '
    'checksum=$checksum',
  );
}

int _expected(String name, int iterations) {
  return name == 'local' ? iterations * 3 + 3 : iterations;
}

void _checkResult(String name, dynamic result, int expected) {
  if (result is Future || result != expected) {
    throw StateError('$name returned $result, expected $expected');
  }
}
