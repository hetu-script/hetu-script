import 'dart:io';

import 'class.dart';
import 'function.dart';

abstract class HS_Extern {
  static Map<String, Bind> bindmap = {
    'println': _println,
    'getln': _getln,
    'now': _now,
  };

  static Map<String, Bind> linkmap = {
    '_literal.toString': _literal_to_string,
  };

  static dynamic _println(HS_Instance instance, List<dynamic> args) {
    for (var arg in args) {
      print(arg);
    }
    return null;
  }

  static dynamic _getln(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
    return HSVal_String(input);
  }

  static dynamic _now(HS_Instance instance, List<dynamic> args) {
    return HSVal_Num(DateTime.now().millisecondsSinceEpoch);
  }

  static dynamic _literal_to_string(HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      var literal = instance.get('_val');
      return HSVal_String(literal);
    }
  }
}
