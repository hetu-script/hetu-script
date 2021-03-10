import 'dart:io';
import 'dart:math';

import 'class.dart';
import 'interpreter.dart';
import 'value.dart';
import 'lexicon.dart';
import 'class.dart' show HT_Instance;

/// Type of external functions in Dart.
typedef HT_External = dynamic Function(
    {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Instance instance});

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_BaseBinding {
  /// A ref of interpreter, initted by [Hetu.init()] function.
  /// For eval script in script it self.
  static Interpreter itp;

  /// Some low level external dart functions for Hetu to use.
  static Map<String, HT_External> dartFunctions = {
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
    'Value.toString': HTVal_Value._to_string,
    'num.parse': HTVal_Number._parse,
    'num.toStringAsFixed': HTVal_Number._to_string_as_fixed,
    'num.truncate': HTVal_Number._truncate,
    'String.isEmpty': HTVal_String._is_empty,
    'String.parse': HTVal_String._parse,
    'String.substring': HTVal_String._substring,
    'List.length': HTVal_List._get_length,
    'List.add': HTVal_List._add,
    'List.clear': HTVal_List._clear,
    'List.removeAt': HTVal_List._remove_at,
    'List.indexOf': HTVal_List._index_of,
    'List.elementAt': HTVal_List._element_at,
    'Map.length': HTVal_Map._get_length,
    'Map.keys': HTVal_Map._get_keys,
    'Map.values': HTVal_Map._get_values,
    'Map.containsKey': HTVal_Map._contains_key,
    'Map.containsValue': HTVal_Map._contains_value,
    'Map.setVal': HTVal_Map._set_val,
    'Map.addAll': HTVal_Map._add_all,
    'Map.clear': HTVal_Map._clear,
    'Map.remove': HTVal_Map._remove,
    'Map.getVal': HTVal_Map._get_val,
    'Map.putIfAbsent': HTVal_Map._put_if_absent,
    'random': _math_random,
    'randomInt': _math_random_int,
    'sqrt': _math_sqrt,
    'log': _math_log,
    'sin': _math_sin,
    'cos': _math_cos,
  };

  static dynamic _typeof(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      return HT_TypeOf(positionalArgs.first).toString();
    }
  }

  static dynamic _help(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var value = positionalArgs.first;
      if (value is HT_Instance) {
        return value.typeid.toString();
      } else {
        return HT_TypeOf(value).toString();
      }
    }
  }

  static dynamic _print(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var sb = StringBuffer();
    for (final string in positionalArgs) {
      sb.write('$string ');
    }
    print(sb.toString());
  }

  static dynamic _string(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var result = StringBuffer();
    for (final arg in positionalArgs) {
      result.write(arg);
    }
    return result.toString();
  }

  static dynamic _system_invoke(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.length >= 2) {
      var func_name = positionalArgs[0];
      var pos_args = positionalArgs[1];
      var named_args = positionalArgs[2];
      return itp?.invoke(func_name, positionalArgs: pos_args, namedArgs: named_args);
    }
  }

  static dynamic _console_write(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) stdout.write(positionalArgs.first);
  }

  static dynamic _console_writeln(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) stdout.writeln(positionalArgs.first);
  }

  static dynamic _console_getln(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      stdout.write('${positionalArgs.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _console_erase_line(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    stdout.write('\x1B[1F\x1B[1G\x1B[1K');
  }

  static dynamic _console_set_title(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var title = positionalArgs.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _console_cls(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  static dynamic _math_random(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    return Random().nextDouble();
  }

  static dynamic _math_random_int(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      final value = (positionalArgs.first as num).truncate();
      return Random().nextInt(value);
    }
  }

  static dynamic _math_sqrt(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return sqrt(value);
    }
  }

  static dynamic _math_log(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return log(value);
    }
  }

  static dynamic _math_sin(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return sin(value);
    }
  }

  static dynamic _math_cos(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      num value = positionalArgs.first;
      return cos(value);
    }
  }

  static dynamic _system_now(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// Abstract base class of all class wrapper for literal values.
abstract class HTVal_Value extends HT_Instance {
  final dynamic value;

  HTVal_Value(this.value, String className, int line, int column, Interpreter interpreter)
      : super(
          interpreter,
          interpreter.fetchGlobal(className),
        );

  //dynamic get value => fetch('_val', null, null, globalInterpreter.curFileName, error: false, from: type);

  static dynamic _to_string(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (instance != null) {
      //var value = instance.fetch('_val', null, null, globalInterpreter.curFileName, from: instance.type);
      return (instance as HTVal_Value).value.toString();
    }
  }
}

/// Class wrapper for literal number.
class HTVal_Number extends HTVal_Value {
  HTVal_Number(num value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.number, line, column, interpreter);

  static dynamic _parse(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      return num.tryParse(positionalArgs.first);
    }
  }

  static dynamic _to_string_as_fixed(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var fractionDigits = 0;
    if (positionalArgs.isNotEmpty) {
      fractionDigits = positionalArgs.first;
    }
    var numObj = (instance as HTVal_Number);
    num number = numObj?.value;
    return number.toStringAsFixed(fractionDigits);
  }

  static dynamic _truncate(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var numObj = (instance as HTVal_Number);
    num number = numObj?.value;
    return number.truncate();
  }
}

/// Class wrapper for literal boolean.
class HTVal_Boolean extends HTVal_Value {
  HTVal_Boolean(bool value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.number, line, column, interpreter);
}

/// Class wrapper for literal string.
class HTVal_String extends HTVal_Value {
  HTVal_String(String value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.string, line, column, interpreter);

  static dynamic _is_empty(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var strObj = (instance as HTVal_String);
    String str = strObj?.value;
    return str?.isEmpty;
  }

  static dynamic _substring(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var strObj = (instance as HTVal_String);
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

  static dynamic _parse(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      return positionalArgs.first.toString();
    }
  }
}

/// Class wrapper for literal list.
class HTVal_List extends HTVal_Value {
  String valueType;

  HTVal_List(List value, int line, int column, Interpreter interpreter, {this.valueType})
      : super(value, HT_Lexicon.list, line, column, interpreter) {
    valueType ??= HT_Lexicon.ANY;
  }

  static dynamic _get_length(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
    return listObj?.value?.length ?? -1;
  }

  static dynamic _add(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
    listObj?.value?.addAll(positionalArgs);
  }

  static dynamic _clear(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    list?.clear();
  }

  static dynamic _remove_at(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    if (positionalArgs.isNotEmpty) {
      list?.removeAt(positionalArgs.first);
    }
  }

  static dynamic _index_of(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    if (positionalArgs.isNotEmpty) {
      return list?.indexOf(positionalArgs.first);
    }
    return -1;
  }

  static dynamic _element_at(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var listObj = (instance as HTVal_List);
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
class HTVal_Map extends HTVal_Value {
  String keyType;
  String valueType;

  HTVal_Map(Map value, int line, int column, Interpreter interpreter, {this.keyType, this.valueType})
      : super(value, HT_Lexicon.map, line, column, interpreter) {
    keyType ??= HT_Lexicon.ANY;
    valueType ??= HT_Lexicon.ANY;
  }

  static dynamic _get_length(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    return (instance as HTVal_Map)?.value?.length ?? -1;
  }

  static dynamic _get_keys(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    return (instance as HTVal_Map)?.value?.keys?.toList() ?? [];
  }

  static dynamic _get_values(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    return (instance as HTVal_Map)?.value?.values?.toList() ?? [];
  }

  static dynamic _contains_key(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsKey(positionalArgs.first);
    }
    return false;
  }

  static dynamic _contains_value(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsValue(positionalArgs.first);
    }
    return false;
  }

  static dynamic _set_val(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if ((positionalArgs.isNotEmpty) && positionalArgs.length >= 2) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      var value = positionalArgs[1];
      if (map != null) {
        map[key] = value;
      }
    }
  }

  static dynamic _add_all(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if ((positionalArgs.isNotEmpty) && (positionalArgs.first is Map)) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      map?.addAll(positionalArgs.first);
    }
  }

  static dynamic _clear(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    var mapObj = (instance as HTVal_Map);
    Map map = mapObj?.value;
    map?.clear();
  }

  static dynamic _remove(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      map.remove(positionalArgs.first);
    }
  }

  static dynamic _get_val(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      return map[key];
    }
  }

  static dynamic _put_if_absent(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance instance}) {
    if (positionalArgs.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = positionalArgs[0];
      var value = positionalArgs[1];
      map.putIfAbsent(key, () => value);
    }
  }
}
