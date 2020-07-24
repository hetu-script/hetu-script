import 'dart:io';

import 'class.dart';
import 'function.dart';
import 'interpreter.dart';

abstract class HS_Extern {
  static Map<String, HS_External> bindmap = {};

  static Map<String, HS_External> linkmap = {
    'System.evalc': _evalc,
    'System.invoke': _invoke,
    'System.readfile': _readfile,
    'System.now': _now,
    'Console.write': _write,
    'Console.writeln': _writeln,
    'Console.print': _print,
    'Console.getln': _getln,
    'Console.movCurUp': _movCurUp,
    'Console.setTitle': _setTitle,
    'Console.cls': _cls,
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

  static dynamic _readfile(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var filepath = args.first.toString();
      return File(filepath).readAsStringSync();
    }
  }

  static dynamic _movCurUp(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
  }

  static dynamic _setTitle(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var title = args.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _cls(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write("\x1B[2J\x1B[0;0H");
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
