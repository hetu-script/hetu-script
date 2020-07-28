import 'dart:io';

import 'package:hetu_script/hetu.dart';

import 'common.dart';
import 'class.dart';
import 'function.dart';
import 'interpreter.dart';

abstract class HS_Buildin {
  static const coreLib = 'class Object {\n'
      '  // external String toString();\n'
      '}\n'
      'class Function {}\n';

  static Map<String, HS_External> bindmap = {};

  static Map<String, HS_External> linkmap = {
    'System.evalc': _system_evalc,
    'System.invoke': _system_invoke,
    'System.readfile': _system_readfile,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.print': _console_print,
    'Console.getln': _console_getln,
    'Console.movCurUp': _console_movCurUp,
    'Console.setTitle': _console_setTitle,
    'Console.cls': _console_cls,
    '_Value.toString': HSVal_Value._to_string,
    'num.parse': HSVal_Num._parse,
    'String.parse': HSVal_String._parse,
    'List._get_length': HSVal_List._get_length,
    'List.add': HSVal_List._add,
    'List.clear': HSVal_List._clear,
    'List.removeAt': HSVal_List._remove_at,
    'List.indexOf': HSVal_List._index_of,
    'List.elementAt': HSVal_List._element_at,
    'Map._get_length': HSVal_Map._get_length,
    'Map._get_keys': HSVal_Map._get_keys,
    'Map._get_values': HSVal_Map._get_values,
    'Map.containsKey': HSVal_Map._contains_key,
    'Map.containsValue': HSVal_Map._contains_value,
    'Map.setVal': HSVal_Map._set_val,
    'Map.addAll': HSVal_Map._add_all,
    'Map.clear': HSVal_Map._clear,
    'Map.remove': HSVal_Map._remove,
    'Map.getVal': HSVal_Map._get_val,
    'Map.putIfAbsent': HSVal_Map._put_if_absent,
  };

  static dynamic _system_evalc(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      try {
        return globalInterpreter.evalc(args.first.toString());
      } catch (e) {
        print(e);
      }
    }
  }

  static dynamic _system_invoke(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
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

  static dynamic _console_write(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.write(args.first);
  }

  static dynamic _console_writeln(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.writeln(args.first);
  }

  static dynamic _console_print(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    for (var arg in args) {
      print(arg);
    }
  }

  static dynamic _console_getln(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _system_readfile(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var filepath = args.first.toString();
      return File(filepath).readAsStringSync();
    }
  }

  static dynamic _console_movCurUp(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write('\x1B[1F\x1B[0G\x1B[0K');
  }

  static dynamic _console_setTitle(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var title = args.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _console_cls(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write("\x1B[2J\x1B[0;0H");
  }

  static dynamic _system_now(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    return HSVal_Num(DateTime.now().millisecondsSinceEpoch);
  }
}

abstract class HSVal_Value extends HS_Instance {
  HSVal_Value(dynamic value, String class_name) : super(class_name) {
    define('_val', HS_TypeOf(value), value: value);
  }

  dynamic get value => fetch('_val', error: false, from: type);

  static dynamic _to_string(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      var value = instance.fetch('_val', from: instance.type);
      return value.toString();
    }
  }
}

class HSVal_Num extends HSVal_Value {
  HSVal_Num(num value) : super(value, HS_Common.Num);

  static dynamic _parse(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return num.tryParse(args.first);
    }
  }
}

class HSVal_Bool extends HSVal_Value {
  HSVal_Bool(bool value) : super(value, HS_Common.Bool);
}

class HSVal_String extends HSVal_Value {
  HSVal_String(String value) : super(value, HS_Common.Str);

  static dynamic _parse(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return args.first.toString();
    }
  }
}

class HSVal_List extends HSVal_Value {
  HSVal_List(List value) : super(value, HS_Common.List);

  static dynamic _get_length(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    var result = list?.length;
    return result == null ? -1 : result;
  }

  static dynamic _add(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    listObj?.value?.addAll(args);
  }

  static dynamic _clear(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    listObj?.value?.clear();
  }

  static dynamic _remove_at(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if ((args != null) && (args.isNotEmpty)) {
      list?.removeAt(args.first);
    }
  }

  static dynamic _index_of(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if ((args != null) && (args.isNotEmpty)) {
      return list?.indexOf(args.first);
    }
    return -1;
  }

  static dynamic _element_at(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    try {
      if ((args.isNotEmpty) && (args.first is int)) {
        return list?.elementAt(args.first);
      }
    } catch (e) {
      if (e is RangeError) {
        // TODO: 打印错误信息到Errors
        return null;
      }
    }
    return null;
  }
}

class HSVal_Map extends HSVal_Value {
  HSVal_Map(Map value) : super(value, HS_Common.Map);

  static dynamic _get_length(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.length;
    return result == null ? -1 : result;
  }

  static dynamic _get_keys(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.keys?.toList();
    return result == null ? [] : result;
  }

  static dynamic _get_values(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.values?.toList();
    return result == null ? [] : result;
  }

  static dynamic _contains_key(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsKey(args.first);
    }
    return false;
  }

  static dynamic _contains_value(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsValue(args.first);
    }
    return false;
  }

  static dynamic _set_val(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if ((args.isNotEmpty) && args.length >= 2) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      var value = args[1];
      if (map != null) {
        map[key] = value;
      }
    }
  }

  static dynamic _add_all(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if ((args.isNotEmpty) && (args.first is Map)) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      map?.addAll(args.first);
    }
  }

  static dynamic _clear(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    map?.clear();
  }

  static dynamic _remove(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      map.remove(args.first);
    }
  }

  static dynamic _get_val(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      return map[key];
    }
  }

  static dynamic _put_if_absent(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      var value = args[1];
      map.putIfAbsent(key, () => value);
    }
  }
}
