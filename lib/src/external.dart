import 'dart:io';

import 'class.dart';
import 'function.dart';
import 'interpreter.dart';

abstract class HS_Extern {
  static Map<String, HS_External> bindmap = {};

  static Map<String, HS_External> linkmap = {
    'System.evalc': _evalc,
    'System.invoke': _invoke,
    'System.write': _write,
    'System.writeln': _writeln,
    'System.print': _print,
    'System.getln': _getln,
    'System.now': _now,
    '_Literal.toString': _literal_to_string,
  };

  static dynamic _evalc(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) interpreter.evalc(args.first.toString());
  }

  static dynamic _invoke(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.length >= 2) {
      var func_name = args[0];
      var class_name = args[1];
      var arguments = <dynamic>[];
      for (var i = 2; i < args.length; ++i) {
        arguments.add(args[i]);
      }
      interpreter.invoke(func_name, classname: class_name, args: arguments);
    }
  }

  static dynamic _write(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.write('${args.first.toString()}');
  }

  static dynamic _writeln(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.writeln('${args.first.toString()}');
  }

  static dynamic _print(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    for (var arg in args) {
      print(arg);
    }
  }

  static dynamic _getln(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _now(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    return HSVal_Num(DateTime.now().millisecondsSinceEpoch);
  }

  static dynamic _literal_to_string(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      var literal = instance.get('_val');
      return literal.toString();
    }
  }
}
