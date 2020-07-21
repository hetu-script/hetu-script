import 'dart:io';

import 'class.dart';
import 'function.dart';

abstract class HetuBuildInFunction {
  static Map<String, Call> bindmap = {
    'println': println,
    'getln': getln,
    'now': now,
  };

  static Instance println(List<Instance> args) {
    for (var arg in args) {
      print(arg);
    }
    return null;
  }

  static LString getln(List<Instance> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
    return LString(input);
  }

  static LNum now(List<Instance> args) {
    return LNum(DateTime.now().millisecondsSinceEpoch);
  }
}
