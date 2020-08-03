import 'dart:io';
import 'dart:math';

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
    'typeOf': _type_of,
    'System.evalc': _system_evalc,
    'System.invoke': _system_invoke,
    'System.readfile': _system_readfile,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.print': _console_print,
    'Console.getln': _console_getln,
    'Console.eraseLine': _console_erase_line,
    'Console.setTitle': _console_set_title,
    'Console.cls': _console_cls,
    '_Value.toString': HSVal_Value._to_string,
    'num.parse': HSVal_Num._parse,
    'num.toStringAsFixed': HSVal_Num._to_string_as_fixed,
    'num.truncate': HSVal_Num._truncate,
    'String._get_isEmpty': HSVal_String._is_empty,
    'String.parse': HSVal_String._parse,
    'String.substring': HSVal_String._substring,
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
    'random': _math_random,
    'randomInt': _math_random_int,
    'sqrt': _math_sqrt,
    'log': _math_log,
    'sin': _math_sin,
    'cos': _math_cos,
  };

  static dynamic _type_of(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return HS_TypeOf(args.first);
    }
  }

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
      var arguments = args[2];
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

  static dynamic _console_erase_line(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write('\x1B[1F\x1B[1G\x1B[1K');
  }

  static dynamic _console_set_title(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var title = args.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _console_cls(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    stdout.write("\x1B[2J\x1B[0;0H");
  }

  static dynamic _math_random(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    return Random().nextDouble();
  }

  static dynamic _math_random_int(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      int value = (args.first as num).truncate();
      return Random().nextInt(value);
    }
  }

  static dynamic _math_sqrt(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sqrt(value);
    }
  }

  static dynamic _math_log(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return log(value);
    }
  }

  static dynamic _math_sin(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sin(value);
    }
  }

  static dynamic _math_cos(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return cos(value);
    }
  }

  static dynamic _system_now(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

abstract class HSVal_Value extends HS_Instance {
  HSVal_Value(dynamic value, String class_name, int line, int column, String file_name)
      : super(globalInterpreter.fetchGlobal(class_name, line, column, file_name,
                from: globalInterpreter.curContext.spaceName) //, line, column, file_name
            ) {
    define('_val', HS_TypeOf(value), line, column, file_name, value: value);
  }

  dynamic get value => fetch('_val', null, null, globalInterpreter.curFileName, error: false, from: type);

  static dynamic _to_string(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      var value = instance.fetch('_val', null, null, globalInterpreter.curFileName, from: instance.type);
      return value.toString();
    }
  }
}

class HSVal_Num extends HSVal_Value {
  HSVal_Num(num value, int line, int column, String file_name) : super(value, HS_Common.Num, line, column, file_name);

  static dynamic _parse(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return num.tryParse(args.first);
    }
  }

  static dynamic _to_string_as_fixed(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      int fractionDigits = 0;
      if (args.isNotEmpty) {
        fractionDigits = args.first;
      }
      var numObj = (instance as HSVal_Num);
      num number = numObj?.value;
      return number.toStringAsFixed(fractionDigits);
    }
  }

  static dynamic _truncate(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var numObj = (instance as HSVal_Num);
    num number = numObj?.value;
    return number.truncate();
  }
}

class HSVal_Bool extends HSVal_Value {
  HSVal_Bool(bool value, int line, int column, String file_name)
      : super(value, HS_Common.Bool, line, column, file_name);
}

class HSVal_String extends HSVal_Value {
  HSVal_String(String value, int line, int column, String file_name)
      : super(value, HS_Common.Str, line, column, file_name);

  static dynamic _is_empty(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var strObj = (instance as HSVal_String);
    String str = strObj?.value;
    return str?.isEmpty;
  }

  static dynamic _parse(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return args.first.toString();
    }
  }

  static dynamic _substring(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var strObj = (instance as HSVal_String);
    String str = strObj?.value;
    if (args.isNotEmpty) {
      int startIndex = args[0];
      int endIndex;
      if (args.length >= 1) {
        endIndex = args[1];
      }
      str?.substring(startIndex, endIndex);
    }
  }
}

class HSVal_List extends HSVal_Value {
  HSVal_List(List value, int line, int column, String file_name)
      : super(value, HS_Common.List, line, column, file_name);

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
    List list = listObj?.value;
    list?.clear();
  }

  static dynamic _remove_at(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
      list?.removeAt(args.first);
    }
  }

  static dynamic _index_of(Interpreter interpreter, HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
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

//TODO：点操作符对于Map也可以直接取成员，这样好吗？
class HSVal_Map extends HSVal_Value {
  HSVal_Map(Map value, int line, int column, String file_name) : super(value, HS_Common.Map, line, column, file_name);

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
