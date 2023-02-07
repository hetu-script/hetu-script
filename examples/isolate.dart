// Example of bi-directional communication between a main thread and isolate.

import 'dart:async';
import 'dart:isolate';

import 'package:hetu_script/hetu_script.dart';

late final ReceivePort mainToIsolatePort, isolateToMainPort;
late final SendPort mainPort;
late final Isolate isolate;

bool isIsolateKilled = false;

int messageIndex = 0;
Map<int, bool> massageReceived = {};

void main() async {
  mainPort = await initIsolate();

  sendMessage(r'''
print('hello world')''');
  sendMessage(r'''
6 * 7''');
  sendMessage(r'''
for (final i in range(100000)) {
  for (final j in range(100000)) {
    final b = 6 * 7
  }
}
'''); // this message will cause the script to consume longer time, and will cause the isolate be killed during script execution.

  print('All messages have been sent.');

  sendMessage('exit');
}

void sendMessage(String message) {
  final id = messageIndex++;

  mainPort.send({
    "id": id,
    "data": message,
  });

  Future.delayed(Duration(seconds: 5), () {
    if (massageReceived[id] == null) {
      if (!isIsolateKilled) {
        print('Isolate took too long to yield result for message id: $id.');
        killIsolate();
      }
    }
  });
}

void onReceivedMessage(dynamic message) {
  if (message is Map) {
    massageReceived[message['id']] = true;
    if (message['data'] == 'exit') {
      print('Isolate exited.');
      killIsolate();
    } else {
      print('''
Received data from isolate:
id: ${message['id']}
data: ${message['data']}
runtimeType: ${message['data'].runtimeType}
''');
    }
  } else {
    throw 'ERROR: Illegal message object: $message';
  }
}

void killIsolate() {
  print('Killing isolate...');
  isolateToMainPort.close();
  isolate.kill();
  isIsolateKilled = true;
}

Future<SendPort> initIsolate() async {
  isIsolateKilled = false;

  final completer = new Completer<SendPort>();
  isolateToMainPort = ReceivePort();
  final sendPort = isolateToMainPort.sendPort;

  isolateToMainPort.listen((data) {
    if (data is SendPort) {
      // If we received a SendPort object from entryPoint function,
      // we will tell main function that the init function is finished.
      // and we send a communicating port to main for sending message from there.
      SendPort port = data;
      completer.complete(port);
    } else {
      onReceivedMessage(data);
    }
  });

  isolate = await Isolate.spawn(entryPoint, sendPort);

  return completer.future;
}

void entryPoint(SendPort isolateToMainPort) {
  final hetu = Hetu(
    config: HetuConfig(printPerformanceStatistics: false),
  );
  hetu.init();

  mainToIsolatePort = ReceivePort();
  isolateToMainPort.send(mainToIsolatePort.sendPort);

  mainToIsolatePort.listen((data) async {
    print('Received data from main():\n$data');
    if (data['data'] == 'exit') {
      // if we received a exit message from main
      // we will exit isolate
      isolateToMainPort.send(data);
    } else {
      final result = await hetu.eval(data['data']);
      isolateToMainPort.send({
        "id": data['id'],
        "data": result,
      });
    }
  });
}
