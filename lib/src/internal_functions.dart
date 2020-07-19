import 'dart:io';

import 'object.dart';

abstract class HetuBuildInFunction {
  static Map<String, HetuFunctionCall> bindmap = {
    'println': println,
    'getln': getln,
    'now': now,
  };

  static HetuObject println(List<HetuObject> args) {
    for (var arg in args) {
      print(arg);
    }
    return HetuObject.Null;
  }

  static HetuString getln(List<HetuObject> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
    return HetuString(input);
  }

  static HetuNum now(List<HetuObject> args) {
    return HetuNum(DateTime.now().millisecondsSinceEpoch);
  }
}
