import 'dart:io';

import 'package:hetu_script/hetu.dart';

import 'common.dart';
import 'class.dart';
import 'function.dart';
import 'interpreter.dart';

abstract class HS_Buildin {
  static const coreLib = 'class Object {}\nclass Function {}\n';

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
    '_Value.toString': HSVal_Value._to_string,
    'List._get_length': HSVal_List._get_length,
    'List.add': HSVal_List._add,
    'List.clear': HSVal_List._clear,
    'List.removeAt': HSVal_List._remove_at,
    'List.indexOf': HSVal_List._index_of,
    'List.elementAt': HSVal_List._element_at
  };

  static dynamic _evalc(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      try {
        interpreter.evalc(args.first.toString());
      } catch (e) {
        print(e);
      }
    }
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
}

abstract class HSVal_Value extends HS_Instance {
  HSVal_Value(dynamic value, String class_name) : super(class_name) {
    define('_val', HS_TypeOf(value), value: value);
  }

  static dynamic _to_string(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      var value = instance.fetch('_val', from: instance.type);
      return value.toString();
    }
  }
}

class HSVal_Num extends HSVal_Value {
  HSVal_Num(num value) : super(value, HS_Common.Num);
}

class HSVal_Bool extends HSVal_Value {
  HSVal_Bool(bool value) : super(value, HS_Common.Bool);
}

class HSVal_String extends HSVal_Value {
  HSVal_String(String value) : super(value, HS_Common.Str);
}

class HSVal_List extends HSVal_Value {
  HSVal_List(List value) : super(value, HS_Common.List);

  List get value => fetch('_val', error: false, from: type);

  static dynamic _get_length(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        return value.length;
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }

  static dynamic _add(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        value.addAll(args);
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }

  static dynamic _clear(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        value.clear();
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }

  static dynamic _remove_at(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        num index = args.first;
        value.removeAt(index);
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }

  static dynamic _index_of(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        dynamic object = args.first;
        return value.indexOf(object);
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }

  static dynamic _element_at(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      List value;
      try {
        value = instance.fetch('_val', from: instance.type);
        int index = args.first;
        return value.elementAt(index);
      } catch (e) {
        if (e is HSErr_Undefined) {
          throw HSErr_NullObject(instance.type);
        } else {
          throw e;
        }
      }
    }
  }
}
