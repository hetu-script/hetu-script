import 'dart:io';
import 'dart:math';

import 'class.dart';
import 'interpreter.dart';
import 'value.dart';
import 'lexicon.dart';
import 'class.dart' show HT_Object;

/// Type of external functions in Dart.
typedef HT_ExternFunc = dynamic Function(HT_Interpreter interpreter,
    {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Object object});

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_BaseBinding {
  static Map<String, HT_Declaration> externVars = {};

  /// Some low level external dart functions for Hetu to use.
  static Map<String, HT_ExternFunc> externFuncs = {
    'typeof': _typeof,
    'help': _help,
    'print': _print,
    'string': _string,
    'System.invoke': _system_invoke,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.getln': _console_getln,
    'Console.eraseLine': _console_erase_line,
    'Console.setTitle': _console_set_title,
    'Console.cls': _console_cls,
    'Value.toString': HT_Instance_Value._to_string,
    'num.parse': HT_Instance_Number._parse,
    'num.toStringAsFixed': HT_Instance_Number._to_string_as_fixed,
    'num.truncate': HT_Instance_Number._truncate,
    'String.isEmpty': HT_Instance_String._is_empty,
    'String.parse': HT_Instance_String._parse,
    'String.substring': HT_Instance_String._substring,
    'List.length': HT_Instance_List._get_length,
    'List.add': HT_Instance_List._add,
    'List.clear': HT_Instance_List._clear,
    'List.removeAt': HT_Instance_List._remove_at,
    'List.indexOf': HT_Instance_List._index_of,
    'List.elementAt': HT_Instance_List._element_at,
    'Map.length': HT_Instance_Map._get_length,
    'Map.keys': HT_Instance_Map._get_keys,
    'Map.values': HT_Instance_Map._get_values,
    'Map.containsKey': HT_Instance_Map._contains_key,
    'Map.containsValue': HT_Instance_Map._contains_value,
    'Map.setVal': HT_Instance_Map._set_val,
    'Map.addAll': HT_Instance_Map._add_all,
    'Map.clear': HT_Instance_Map._clear,
    'Map.remove': HT_Instance_Map._remove,
    'Map.getVal': HT_Instance_Map._get_val,
    'Map.putIfAbsent': HT_Instance_Map._put_if_absent,
    'random': _math_random,
    'randomInt': _math_random_int,
    'sqrt': _math_sqrt,
    'log': _math_log,
    'sin': _math_sin,
    'cos': _math_cos,
  };

  static dynamic _typeof(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      return HT_TypeOf(positionalArgs.first).toString();
    }
  }

  static dynamic _help(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var value = positionalArgs.first;
      if (value is HT_Object) {
        return value.typeid.toString();
      } else {
        return HT_TypeOf(value).toString();
      }
    }
  }

  static dynamic _print(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var sb = StringBuffer();
    for (final string in positionalArgs) {
      sb.write('$string ');
    }
    print(sb.toString());
  }

  static dynamic _string(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var result = StringBuffer();
    for (final arg in positionalArgs) {
      result.write(arg);
    }
    return result.toString();
  }

  static dynamic _system_invoke(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.length >= 2) {
      var func_name = positionalArgs[0];
      var pos_args = positionalArgs[1];
      var named_args = positionalArgs[2];
      return interpreter.invoke(func_name, positionalArgs: pos_args, namedArgs: named_args);
    }
  }

  static dynamic _console_write(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) stdout.write(positionalArgs.first);
  }

  static dynamic _console_writeln(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) stdout.writeln(positionalArgs.first);
  }

  static dynamic _console_getln(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      stdout.write('${positionalArgs.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _console_erase_line(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    stdout.write('\x1B[1F\x1B[1G\x1B[1K');
  }

  static dynamic _console_set_title(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var title = positionalArgs.first.toString();
      stdout.write('\x1b]0;$title\x07');
    }
  }

  static dynamic _console_cls(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  static dynamic _math_random(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return Random().nextDouble();
  }

  static dynamic _math_random_int(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      final value = (positionalArgs.first as num).truncate();
      return Random().nextInt(value);
    }
  }

  static dynamic _math_sqrt(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return sqrt(value);
    }
  }

  static dynamic _math_log(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return log(value);
    }
  }

  static dynamic _math_sin(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return sin(value);
    }
  }

  static dynamic _math_cos(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return cos(value);
    }
  }

  static dynamic _system_now(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// Abstract base class of all class wrapper for literal values.
abstract class HT_Instance_Value extends HT_Object {
  final dynamic value;

  HT_Instance_Value(this.value, String className, HT_Interpreter interpreter)
      : super(
          interpreter,
          interpreter.fetchGlobal(className),
        );

  static dynamic _to_string(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (object != null) {
      return (object as HT_Instance_Value).value.toString();
    }
  }
}

/// Class wrapper for literal number.
class HT_Instance_Number extends HT_Instance_Value {
  HT_Instance_Number(num value, HT_Interpreter interpreter) : super(value, HT_Lexicon.number, interpreter);

  static dynamic _parse(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      return num.tryParse(positionalArgs.first);
    }
  }

  static dynamic _to_string_as_fixed(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var fractionDigits = 0;
    if (positionalArgs.isNotEmpty) {
      fractionDigits = positionalArgs.first;
    }
    var numObj = (object as HT_Instance_Number);
    num number = numObj?.value;
    return number.toStringAsFixed(fractionDigits);
  }

  static dynamic _truncate(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var numObj = (object as HT_Instance_Number);
    num number = numObj?.value;
    return number.truncate();
  }
}

/// Class wrapper for literal boolean.
class HT_Instance_Boolean extends HT_Instance_Value {
  HT_Instance_Boolean(bool value, HT_Interpreter interpreter) : super(value, HT_Lexicon.number, interpreter);
}

/// Class wrapper for literal string.
class HT_Instance_String extends HT_Instance_Value {
  HT_Instance_String(String value, HT_Interpreter interpreter) : super(value, HT_Lexicon.string, interpreter);

  static dynamic _is_empty(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var strObj = (object as HT_Instance_String);
    String str = strObj?.value;
    return str?.isEmpty;
  }

  static dynamic _substring(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var strObj = (object as HT_Instance_String);
    String str = strObj?.value;
    if (positionalArgs.isNotEmpty) {
      int startIndex = positionalArgs[0];
      int endIndex;
      if (positionalArgs.length >= 2) {
        endIndex = positionalArgs[1];
      }
      return str?.substring(startIndex, endIndex);
    }
  }

  static dynamic _parse(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      return positionalArgs.first.toString();
    }
  }
}

/// Class wrapper for literal list.
class HT_Instance_List extends HT_Instance_Value {
  String valueType;

  HT_Instance_List(List value, HT_Interpreter interpreter, {this.valueType = HT_Lexicon.ANY})
      : super(value, HT_Lexicon.list, interpreter);

  static dynamic _get_length(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    return listObj?.value?.length ?? -1;
  }

  static dynamic _add(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    listObj?.value?.addAll(positionalArgs);
  }

  static dynamic _clear(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    List list = listObj?.value;
    list?.clear();
  }

  static dynamic _remove_at(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    List list = listObj?.value;
    if (positionalArgs.isNotEmpty) {
      list?.removeAt(positionalArgs.first);
    }
  }

  static dynamic _index_of(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    List list = listObj?.value;
    if (positionalArgs.isNotEmpty) {
      return list?.indexOf(positionalArgs.first);
    }
    return -1;
  }

  static dynamic _element_at(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var listObj = (object as HT_Instance_List);
    List list = listObj?.value;
    try {
      if ((positionalArgs.isNotEmpty) && (positionalArgs.first is int)) {
        return list?.elementAt(positionalArgs.first);
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

/// Class wrapper for literal map.
class HT_Instance_Map extends HT_Instance_Value {
  String keyType;
  String valueType;

  HT_Instance_Map(Map value, HT_Interpreter interpreter,
      {this.keyType = HT_Lexicon.ANY, this.valueType = HT_Lexicon.ANY})
      : super(value, HT_Lexicon.map, interpreter);

  static dynamic _get_length(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return (object as HT_Instance_Map)?.value?.length ?? -1;
  }

  static dynamic _get_keys(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return (object as HT_Instance_Map)?.value?.keys?.toList() ?? [];
  }

  static dynamic _get_values(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return (object as HT_Instance_Map)?.value?.values?.toList() ?? [];
  }

  static dynamic _contains_key(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsKey(positionalArgs.first);
    }
    return false;
  }

  static dynamic _contains_value(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsValue(positionalArgs.first);
    }
    return false;
  }

  static dynamic _set_val(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if ((positionalArgs.isNotEmpty) && positionalArgs.length >= 2) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      var value = positionalArgs[1];
      if (map != null) {
        map[key] = value;
      }
    }
  }

  static dynamic _add_all(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if ((positionalArgs.isNotEmpty) && (positionalArgs.first is Map)) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      map?.addAll(positionalArgs.first);
    }
  }

  static dynamic _clear(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    var mapObj = (object as HT_Instance_Map);
    Map map = mapObj?.value;
    map?.clear();
  }

  static dynamic _remove(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      map.remove(positionalArgs.first);
    }
  }

  static dynamic _get_val(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      return map[key];
    }
  }

  static dynamic _put_if_absent(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (object as HT_Instance_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      var value = positionalArgs[1];
      map.putIfAbsent(key, () => value);
    }
  }
}
