import 'dart:io';
import 'dart:math';

import 'package:hetu_script/hetu.dart';

import 'common.dart';
import 'class.dart';
import 'function.dart';
import 'interpreter.dart';
import 'value.dart';

abstract class HS_Buildin {
  static const coreLib = 'class Object {}\n'
      'class Function {}\n';

  static Map<String, HS_External> functions = {
    'typeof': _typeof,
    'help': _help,
    'print': _print,
    'string': _string,
    'System.evalc': _system_evalc,
    'System.invoke': _system_invoke,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.getln': _console_getln,
    'Console.eraseLine': _console_erase_line,
    'Console.setTitle': _console_set_title,
    'Console.cls': _console_cls,
    'Value.toString': HSVal_Value._to_string,
    'num.parse': HSVal_Number._parse,
    'num.toStringAsFixed': HSVal_Number._to_string_as_fixed,
    'num.truncate': HSVal_Number._truncate,
    'String.__get__isEmpty': HSVal_String._is_empty,
    'String.parse': HSVal_String._parse,
    'String.substring': HSVal_String._substring,
    'List.__get__length': HSVal_List._get_length,
    'List.add': HSVal_List._add,
    'List.clear': HSVal_List._clear,
    'List.removeAt': HSVal_List._remove_at,
    'List.indexOf': HSVal_List._index_of,
    'List.elementAt': HSVal_List._element_at,
    'Map.__get__length': HSVal_Map._get_length,
    'Map.__get__keys': HSVal_Map._get_keys,
    'Map.__get__values': HSVal_Map._get_values,
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

  static dynamic _typeof(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return HS_TypeOf(args.first).toString();
    }
  }

  static dynamic _help(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var value = args.first;
      if (value is HS_Instance) {
        return value.typeid;
      } else {
        return HS_TypeOf(value);
      }
    }
  }

  static dynamic _print(HS_Instance instance, List<dynamic> args) {
    var sb = StringBuffer();
    for (var arg in args) {
      sb.write('$arg ');
    }
    print(sb.toString());
  }

  static dynamic _string(HS_Instance instance, List<dynamic> args) {
    var result = StringBuffer();
    for (var arg in args) {
      result.write(arg);
    }
    return result.toString();
  }

  static dynamic _system_evalc(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      try {
        return hetu.evalc(args.first.toString());
      } catch (e) {
        print(e);
      }
    }
  }

  static dynamic _system_invoke(HS_Instance instance, List<dynamic> args) {
    if (args.length >= 2) {
      var func_name = args[0];
      var className = args[1];
      var arguments = args[2];
      hetu.invoke(func_name, classname: className, args: arguments);
    }
  }

  static dynamic _console_write(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.write(args.first);
  }

  static dynamic _console_writeln(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) stdout.writeln(args.first);
  }

  static dynamic _console_getln(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _console_erase_line(HS_Instance instance, List<dynamic> args) {
    stdout.write('\x1B[1F\x1B[1G\x1B[1K');
  }

  static dynamic _console_set_title(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var title = args.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _console_cls(HS_Instance instance, List<dynamic> args) {
    stdout.write("\x1B[2J\x1B[0;0H");
  }

  static dynamic _math_random(HS_Instance instance, List<dynamic> args) {
    return Random().nextDouble();
  }

  static dynamic _math_random_int(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      int value = (args.first as num).truncate();
      return Random().nextInt(value);
    }
  }

  static dynamic _math_sqrt(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sqrt(value);
    }
  }

  static dynamic _math_log(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return log(value);
    }
  }

  static dynamic _math_sin(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sin(value);
    }
  }

  static dynamic _math_cos(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      num value = args.first;
      return cos(value);
    }
  }

  static dynamic _system_now(HS_Instance instance, List<dynamic> args) {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

abstract class HSVal_Value extends HS_Instance {
  final dynamic value;

  HSVal_Value(this.value, String className, int line, int column, Interpreter interpreter)
      : super(interpreter.globals.fetch(
          className, line, column, interpreter,
          //from: globalInterpreter.curContext.spaceName
        ) //, line, column, fileName
            ) {}

  //dynamic get value => fetch('_val', null, null, globalInterpreter.curFileName, error: false, from: type);

  static dynamic _to_string(HS_Instance instance, List<dynamic> args) {
    if (instance != null) {
      //var value = instance.fetch('_val', null, null, globalInterpreter.curFileName, from: instance.type);
      return (instance as HSVal_Value).value.toString();
    }
  }
}

class HSVal_Number extends HSVal_Value {
  HSVal_Number(num value, int line, int column, Interpreter interpreter)
      : super(value, HS_Common.number, line, column, interpreter);

  static dynamic _parse(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return num.tryParse(args.first);
    }
  }

  static dynamic _to_string_as_fixed(HS_Instance instance, List<dynamic> args) {
    int fractionDigits = 0;
    if (args.isNotEmpty) {
      fractionDigits = args.first;
    }
    var numObj = (instance as HSVal_Number);
    num number = numObj?.value;
    return number.toStringAsFixed(fractionDigits);
  }

  static dynamic _truncate(HS_Instance instance, List<dynamic> args) {
    var numObj = (instance as HSVal_Number);
    num number = numObj?.value;
    return number.truncate();
  }
}

class HSVal_Boolean extends HSVal_Value {
  HSVal_Boolean(bool value, int line, int column, Interpreter interpreter)
      : super(value, HS_Common.number, line, column, interpreter);
}

class HSVal_String extends HSVal_Value {
  HSVal_String(String value, int line, int column, Interpreter interpreter)
      : super(value, HS_Common.string, line, column, interpreter);

  static dynamic _is_empty(HS_Instance instance, List<dynamic> args) {
    var strObj = (instance as HSVal_String);
    String str = strObj?.value;
    return str?.isEmpty;
  }

  static dynamic _substring(HS_Instance instance, List<dynamic> args) {
    var strObj = (instance as HSVal_String);
    String str = strObj?.value;
    if (args.isNotEmpty) {
      int startIndex = args[0];
      int endIndex;
      if (args.length >= 1) {
        endIndex = args[1];
      }
      return str?.substring(startIndex, endIndex);
    }
  }

  static dynamic _parse(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      return args.first.toString();
    }
  }
}

class HSVal_List extends HSVal_Value {
  final String valueType;

  HSVal_List(List value, int line, int column, Interpreter interpreter, {this.valueType = HS_Common.ANY})
      : super(value, HS_Common.list, line, column, interpreter);

  static dynamic _get_length(HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    var result = list?.length;
    return result == null ? -1 : result;
  }

  static dynamic _add(HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    listObj?.value?.addAll(args);
  }

  static dynamic _clear(HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    list?.clear();
  }

  static dynamic _remove_at(HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
      list?.removeAt(args.first);
    }
  }

  static dynamic _index_of(HS_Instance instance, List<dynamic> args) {
    var listObj = (instance as HSVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
      return list?.indexOf(args.first);
    }
    return -1;
  }

  static dynamic _element_at(HS_Instance instance, List<dynamic> args) {
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
  final String keyType;
  final String valueType;

  HSVal_Map(Map value, int line, int column, Interpreter interpreter,
      {this.keyType = HS_Common.ANY, this.valueType = HS_Common.ANY})
      : super(value, HS_Common.map, line, column, interpreter);

  static dynamic _get_length(HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.length;
    return result == null ? -1 : result;
  }

  static dynamic _get_keys(HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.keys?.toList();
    return result == null ? [] : result;
  }

  static dynamic _get_values(HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    var result = map?.values?.toList();
    return result == null ? [] : result;
  }

  static dynamic _contains_key(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsKey(args.first);
    }
    return false;
  }

  static dynamic _contains_value(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsValue(args.first);
    }
    return false;
  }

  static dynamic _set_val(HS_Instance instance, List<dynamic> args) {
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

  static dynamic _add_all(HS_Instance instance, List<dynamic> args) {
    if ((args.isNotEmpty) && (args.first is Map)) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      map?.addAll(args.first);
    }
  }

  static dynamic _clear(HS_Instance instance, List<dynamic> args) {
    var mapObj = (instance as HSVal_Map);
    Map map = mapObj?.value;
    map?.clear();
  }

  static dynamic _remove(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      map.remove(args.first);
    }
  }

  static dynamic _get_val(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      return map[key];
    }
  }

  static dynamic _put_if_absent(HS_Instance instance, List<dynamic> args) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HSVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      var value = args[1];
      map.putIfAbsent(key, () => value);
    }
  }
}
