import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart vm_cpu_samples.dart <vm-service-ws-uri>');
    exitCode = 64;
    return;
  }

  final socket = await WebSocket.connect(args.single);
  final pending = <int, Completer<Map<String, dynamic>>>{};
  var nextId = 1;

  socket.listen((data) {
    final message = jsonDecode(data as String) as Map<String, dynamic>;
    final completer = pending.remove(message['id']);
    if (completer == null) return;
    final error = message['error'];
    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete(message['result'] as Map<String, dynamic>);
    }
  });

  Future<Map<String, dynamic>> rpc(
    String method, [
    Map<String, dynamic> params = const {},
  ]) {
    final id = nextId++;
    final completer = Completer<Map<String, dynamic>>();
    pending[id] = completer;
    socket.add(jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params}));
    return completer.future;
  }

  try {
    final vm = await rpc('getVM');
    final isolates = vm['isolates'] as List<dynamic>;
    if (isolates.isEmpty) throw StateError('No isolates found');
    final isolate = isolates.single as Map<String, dynamic>;
    final isolateId = isolate['id'] as String;
    final samples = await rpc('getCpuSamples', {
      'isolateId': isolateId,
      'timeExtentMicros': 30000000,
    });
    final functions = samples['functions'] as List<dynamic>;
    final cpuSamples = samples['samples'] as List<dynamic>;
    final inclusive = List<int>.filled(functions.length, 0);
    final exclusive = List<int>.filled(functions.length, 0);

    for (final sample in cpuSamples.cast<Map<String, dynamic>>()) {
      final stack = (sample['stack'] as List<dynamic>).cast<int>();
      if (stack.isEmpty) continue;
      if (stack.first >= 0 && stack.first < functions.length) {
        exclusive[stack.first]++;
      }
      for (final index in stack.toSet()) {
        if (index >= 0 && index < functions.length) inclusive[index]++;
      }
    }

    final indexes = List<int>.generate(functions.length, (index) => index)
      ..sort((a, b) => exclusive[b].compareTo(exclusive[a]));
    final sampleCount = samples['sampleCount'] as int;
    print('samples=$sampleCount functions=${functions.length}');
    for (final index in indexes.take(35)) {
      if (exclusive[index] == 0 && inclusive[index] == 0) continue;
      final function = functions[index] as Map<String, dynamic>;
      final name = function['name'] ?? function['function']?['name'];
      final owner = function['function']?['owner']?['name'] ?? '';
      final url = function['resolvedUrl'] ?? function['function']?['location']?['script']?['uri'] ?? '';
      print('exclusive=${(exclusive[index] * 100 / sampleCount).toStringAsFixed(1)}% '
          'inclusive=${(inclusive[index] * 100 / sampleCount).toStringAsFixed(1)}% '
          '$owner.$name $url');
    }
    final isolateInfo = await rpc('getIsolate', {'isolateId': isolateId});
    final pauseEvent = isolateInfo['pauseEvent'];
    if (pauseEvent?['kind'] == 'PauseExit') {
      await rpc('resume', {'isolateId': isolateId});
    }
  } finally {
    await socket.close();
  }
}
