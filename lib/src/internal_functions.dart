import 'dart:io';

import 'class.dart';
import 'function.dart';

abstract class HetuBuildInFunction {
  static Map<String, Call> bindmap = {
    'println': println,
    'getln': getln,
    'now': now,
  };

  static Map<String, Call> linkmap = {};

  static HS_Instance println(List<HS_Instance> args) {
    for (var arg in args) {
      print(arg);
    }
    return null;
  }

  static HSVal_String getln(List<HS_Instance> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
    return HSVal_String(input);
  }

  static HSVal_Num now(List<HS_Instance> args) {
    return HSVal_Num(DateTime.now().millisecondsSinceEpoch);
  }
}
