import 'dart:math' as math;

import 'package:hetu_script/hetu_script.dart';

const _loopSource = r'''
function emptyTarget() {}

function identity(x) {
  return x
}

function makeAdder(x) {
  return (y) => x + y
}

final addOne = makeAdder(1)

function namedAdd(value: num, {increment: num = 1}) {
  return value + increment
}

function sum(...args) {
  var result = 0
  for (final value in args) {
    result += value
  }
  return result
}

function add(a, b) {
  return a + b
}

function runConstant(n) {
  var intValue = 0
  var floatValue = 0.0
  var stringValue = ''
  var i = 0
  while (i < n) {
    intValue = 123456789
    floatValue = 3.1415926
    stringValue = 'constant, 常量'
    ++i
  }
  return i
}

function runUtf8(n) {
  var value = ''
  var i = 0
  while (i < n) {
    value = 'prefix-${i}-世界'
    ++i
  }
  return i
}

function runEmpty(n) {
  var i = 0
  while (i < n) {
    emptyTarget()
    ++i
  }
  return i
}

function runIdentity(n) {
  var i = 0
  while (i < n) {
    i = identity(i + 1)
  }
  return i
}

function runClosure(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = addOne(result)
    ++i
  }
  return result
}

function runNamed(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = namedAdd(result, increment: 1)
    ++i
  }
  return result
}

function runVariadic(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = sum(result, 1)
    ++i
  }
  return result
}

function runSpread(n) {
  var result = 0
  var i = 0
  while (i < n) {
    final args = [result, 1]
    result = add(...args)
    ++i
  }
  return result
}
''';

final _scenarios = <String, (String, int, bool)>{
  'constant': ('runConstant', 100000, false),
  'utf8': ('runUtf8', 100000, false),
  'empty': ('runEmpty', 200000, false),
  'identity': ('runIdentity', 200000, false),
  'closure': ('runClosure', 100000, false),
  'named': ('runNamed', 100000, false),
  'variadic': ('runVariadic', 100000, false),
  'spread': ('runSpread', 100000, false),
  'stack_trace': ('runIdentity', 200000, true),
};

void main(List<String> args) {
  final selected = args.isEmpty ? _scenarios.keys : args.take(1);
  final iterationOverride = args.length > 1 ? int.parse(args[1]) : null;
  for (final name in selected) {
    final scenario = _scenarios[name];
    if (scenario == null) {
      throw ArgumentError.value(name, 'scenario', 'Unknown scenario');
    }
    _runScenario(
      name,
      functionName: scenario.$1,
      iterations: iterationOverride ?? scenario.$2,
      showHetuStackTrace: scenario.$3,
    );
  }
}

void _runScenario(
  String name, {
  required String functionName,
  required int iterations,
  required bool showHetuStackTrace,
}) {
  final hetu = Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      showHetuStackTrace: showHetuStackTrace,
    ),
  );
  hetu.init();
  hetu.eval(_loopSource);

  final warmupIterations = math.min(iterations, 10000);
  final warmup = hetu.invoke(functionName, positionalArgs: [warmupIterations]);
  _checkResult(name, warmup, warmupIterations);

  final samples = <int>[];
  var checksum = 0;
  for (var i = 0; i < 5; ++i) {
    final stopwatch = Stopwatch()..start();
    final result = hetu.invoke(functionName, positionalArgs: [iterations]);
    stopwatch.stop();
    _checkResult(name, result, iterations);
    checksum = result as int;
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  print(
    '$name: calls=$iterations samples_us=$samples median_us=$median '
    'us_per_call=${(median / iterations).toStringAsFixed(3)} '
    'stack_trace=$showHetuStackTrace checksum=$checksum',
  );
}

void _checkResult(String name, dynamic result, int expected) {
  if (result is Future) {
    throw StateError('$name unexpectedly returned a Future');
  }
  if (result != expected) {
    throw StateError('$name returned $result, expected $expected');
  }
}
