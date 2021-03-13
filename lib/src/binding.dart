import 'dart:io';
import 'dart:math';

import 'class.dart';
import 'interpreter.dart';
import 'value.dart';
import 'lexicon.dart';
import 'class.dart' show HT_Object;
import 'errors.dart';

/// Type of external functions in Dart.
typedef HT_ExternFunc = dynamic Function(HT_Interpreter interpreter,
    {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Object object});

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_BaseBinding {
  /// Some low level external dart functions for Hetu to use.
  static Map<String, HT_ExternFunc> externFuncs = {
    'typeof': _typeof,
    'help': _help,
    'print': _print,
    'string': _string,
    'random': _math_random,
    'randomInt': _math_random_int,
    'sqrt': _math_sqrt,
    'log': _math_log,
    'sin': _math_sin,
    'cos': _math_cos,
    'num.parse': _num_parse, // static 函数
    'bool.parse': _bool_parse, // static 函数
    'String.parse': _string_parse, // static 函数
    'System.invoke': _system_invoke,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.getln': _console_getln,
    'Console.eraseLine': _console_erase_line,
    'Console.setTitle': _console_set_title,
    'Console.cls': _console_cls,
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

  static dynamic _num_parse(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      return num.tryParse(positionalArgs.first);
    }
  }

  static dynamic _bool_parse(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      final value = positionalArgs.first;
      if (value is bool) {
        return value;
      } else if (value is num) {
        if (value != 0) {
          return true;
        } else {
          return false;
        }
      } else if (value is String) {
        return value.isNotEmpty;
      } else {
        if (value != null) {
          return true;
        } else {
          return false;
        }
      }
    }
  }

  static dynamic _string_parse(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    if (positionalArgs.isNotEmpty) {
      return positionalArgs.first.toString();
    }
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

  static dynamic _system_now(HT_Interpreter interpreter,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) {
    return DateTime.now().millisecondsSinceEpoch;
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
}

/// Abstract base class of all class wrapper for literal values.
abstract class HT_DartObject with HT_Reflect {
  final dynamic value;

  HT_DartObject(this.value);
}

/// Class wrapper for dart number.
class HT_DartObject_Number extends HT_DartObject {
  HT_DartObject_Number(num value) : super(value);

  @override
  final typeid = HT_Type.number;

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'toStringAsFixed':
        return value.toStringAsFixed;
      case 'truncate':
        return value.truncate;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Class wrapper for dart boolean.
class HT_DartObject_Boolean extends HT_DartObject {
  HT_DartObject_Boolean(bool value) : super(value);

  @override
  final typeid = HT_Type.boolean;

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'parse':
        return value.toString;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Class wrapper for dart string.
class HT_DartObject_String extends HT_DartObject {
  HT_DartObject_String(String value) : super(value);

  @override
  final typeid = HT_Type.string;

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'isEmpty':
        return value.isEmpty;
      case 'subString':
        return value.substring;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Class wrapper for dart list.
class HT_DartObject_List extends HT_DartObject {
  String valueType;

  HT_DartObject_List(List value, {this.valueType = HT_Lexicon.ANY}) : super(value);

  @override
  final typeid = HT_Type.list;

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'length':
        return value.length;
      case 'isEmpty':
        return value.isEmpty;
      case 'isNotEmpty':
        return value.isNotEmpty;
      case 'add':
        return value.add;
      case 'addAll':
        return value.addAll;
      case 'clear':
        return value.clear;
      case 'removeAt':
        return value.removeAt;
      case 'indexOf':
        return value.indexOf;
      case 'elementAt':
        return value.elementAt;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Class wrapper for dart map.
class HT_DartObject_Map extends HT_DartObject {
  String keyType;
  String valueType;

  HT_DartObject_Map(Map value, {this.keyType = HT_Lexicon.ANY, this.valueType = HT_Lexicon.ANY}) : super(value);

  @override
  final typeid = HT_Type.map;

  @override
  dynamic getProperty(String id) {
    switch (id) {
      case 'length':
        return value.length;
      case 'isEmpty':
        return value.isEmpty;
      case 'isNotEmpty':
        return value.isNotEmpty;
      case 'keys':
        return value.keys;
      case 'values':
        return value.values;
      case 'containsKey':
        return value.containsKey;
      case 'containsValue':
        return value.containsValue;
      // TODO: subGet/Set、memberGet/Set和call本质都应该是函数（__sub__get__, __sub__set__）
      case '__sub__get__':
        return;
      case '__sub__set__':
        return;
      case 'addAll':
        return value.addAll;
      case 'clear':
        return value.clear;
      case 'remove':
        return value.remove;
      case 'putIfAbsent':
        return value.putIfAbsent;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void setProperty(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}
