import 'dart:io';

import 'class.dart';
import 'function.dart';

abstract class HS_Extern {
  static Map<String, HS_External> bindmap = {};

  static Map<String, HS_External> linkmap = {
    'System.write': _write,
    'System.writeln': _writeln,
    'System.print': _print,
    'System.getln': _getln,
    'System.now': _now,
    '_Literal.toString': _literal_to_string,
  };

  static dynamic _write(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.write('${args.first.toString()}');
  }

  static dynamic _writeln(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.writeln('${args.first.toString()}');
  }

  static dynamic _print(HS_Instance instance, List<dynamic> args) {
    for (var arg in args) {
      print(arg);
    }
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
      return literal.toString();
    }
  }
}
