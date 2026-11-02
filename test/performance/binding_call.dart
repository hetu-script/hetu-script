import 'dart:math' as math;

import 'package:hetu_script/binding.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';

class BenchmarkCounter {
  int value = 0;

  int add(int amount) {
    value += amount;
    return value;
  }
}

class BenchmarkCounterBinding extends HTExternalClass {
  BenchmarkCounterBinding() : super('BenchCounter');

  @override
  dynamic memberGet(
    String id, {
    String? from,
    bool isRecursive = false,
    bool ignoreUndefined = false,
  }) {
    if (id == 'BenchCounter') {
      return ({positionalArgs, namedArgs}) => BenchmarkCounter();
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }

  @override
  dynamic instanceMemberGet(
    dynamic instance,
    String id, {
    bool ignoreUndefined = false,
  }) {
    final object = instance as BenchmarkCounter;
    switch (id) {
      case 'value':
        return object.value;
      case 'add':
        return ({object, positionalArgs, namedArgs}) =>
            (object as BenchmarkCounter).add(positionalArgs.first as int);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void instanceMemberSet(
    dynamic instance,
    String id,
    dynamic value, {
    bool ignoreUndefined = false,
  }) {
    final object = instance as BenchmarkCounter;
    if (id == 'value') {
      object.value = value as int;
    } else if (!ignoreUndefined) {
      throw HTError.undefined(id);
    }
  }
}

int _rawIdentity(int value) => value + 1;

int _runTypedefCallback(int Function(int) callback, int count) {
  var result = 0;
  for (var i = 0; i < count; ++i) {
    result = callback(result);
  }
  return result;
}

const _source = r'''
external class BenchCounter {
  constructor()
  var value: int
  function add(amount: int) -> int
}

external function externalIdentity(value)
external function rawIdentity(value)
external function runScriptCallback(callback, n)
external function runTypedefCallback(callback, n)

final counter = BenchCounter()
final numbers = [1]

function scriptIdentity(value) {
  return value + 1
}

function [DartIntFunction] typedefIdentity(value) {
  return value + 1
}

function nestedIdentity(value) {
  return externalIdentity(value)
}

function runExternalFunction(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = externalIdentity(result)
    ++i
  }
  return result
}

function runRawFunction(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result = rawIdentity(result)
    ++i
  }
  return result
}

function runExternalMethod(n) {
  counter.value = 0
  var i = 0
  while (i < n) {
    counter.add(1)
    ++i
  }
  return counter.value
}

function runExternalProperty(n) {
  counter.value = 0
  var i = 0
  while (i < n) {
    counter.value = counter.value + 1
    ++i
  }
  return counter.value
}

function runDartToScript(n) {
  return runScriptCallback(scriptIdentity, n)
}

function runNestedCallback(n) {
  return runScriptCallback(nestedIdentity, n)
}

function runTypedef(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result += runTypedefCallback(typedefIdentity, 1)
    ++i
  }
  return result
}

function runListProperty(n) {
  var result = 0
  var i = 0
  while (i < n) {
    result += numbers.length
    ++i
  }
  return result
}
''';

final _scenarios = <String, (String, int)>{
  'external_function': ('runExternalFunction', 100000),
  'raw_function': ('runRawFunction', 100000),
  'external_method': ('runExternalMethod', 100000),
  'external_property': ('runExternalProperty', 100000),
  'dart_to_script': ('runDartToScript', 100000),
  'nested_callback': ('runNestedCallback', 100000),
  'typedef_callback': ('runTypedef', 100000),
  'list_property': ('runListProperty', 100000),
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
    );
  }
}

void _runScenario(
  String name, {
  required String functionName,
  required int iterations,
}) {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init(
    externalFunctions: {
      'externalIdentity': ({positionalArgs, namedArgs}) =>
          (positionalArgs.first as num).toInt() + 1,
      'rawIdentity': _rawIdentity,
      'runScriptCallback': ({positionalArgs, namedArgs}) {
        final callback = positionalArgs[0] as HTFunction;
        final count = positionalArgs[1] as int;
        var result = 0;
        for (var i = 0; i < count; ++i) {
          result = callback.call(positionalArgs: [result]) as int;
        }
        return result;
      },
      'runTypedefCallback': ({positionalArgs, namedArgs}) {
        final callback = positionalArgs[0] as int Function(int);
        final count = positionalArgs[1] as int;
        return _runTypedefCallback(callback, count);
      },
    },
    externalFunctionTypedef: {
      'DartIntFunction': (HTFunction function) {
        return (int value) => function.call(positionalArgs: [value]) as int;
      },
    },
    externalClasses: [BenchmarkCounterBinding()],
    externalTypeReflections: [
      (object) => object is BenchmarkCounter ? 'BenchCounter' : null,
    ],
  );
  hetu.eval(_source);

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
    'checksum=$checksum',
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
