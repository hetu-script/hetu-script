import 'dart:io';
import 'dart:math' as math;

import 'class.dart';
import 'interpreter.dart';
import 'value.dart';
import 'class.dart' show HT_Object;
import 'errors.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_ExternClass {
  dynamic fetch(String id);

  void assign(String id, dynamic value);

  // dynamic call(String id, HT_Interpreter interpreter,
  //     {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Object object});
}

class HT_ExternClass_TopLevel extends HT_ExternClass {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'typeof':
        return (dynamic value) => HT_TypeOf(value).toString();
        break;
      case 'help':
        return (dynamic value) {
          if (value is HT_Object) {
            return value.typeid.toString();
          } else {
            return HT_TypeOf(value).toString();
          }
        };
        break;
      case 'print':
        return (dynamic value) => print(value);
        // var sb = StringBuffer();
        // for (final arg in positionalArgs) {
        //   sb.write('${arg.toString()} ');
        // }
        // print(sb.toString());
        break;
      case 'string':
        return (dynamic value) => value.toString();
        // var result = StringBuffer();
        // for (final arg in positionalArgs) {
        //   result.write(arg.toString());
        // }
        // return result.toString();
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) => throw HTErr_Undefined(id);
}

class HT_ExternClass_Math extends HT_ExternClass {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'random':
        return () => math.Random().nextDouble();
        break;
      case 'randomInt':
        return ([int max]) => math.Random().nextInt(max);
        break;
      case 'sqrt':
        return (num x) => math.sqrt(x);
        break;
      case 'log':
        return (num x) => math.log(x);
        break;
      case 'sin':
        return (num x) => math.sin(x);
        break;
      case 'cos':
        return (num x) => math.cos(x);
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) => throw HTErr_Undefined(id);

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

class HT_ExternClass_Number extends HT_ExternClass {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'parse':
        return (String value) => num.tryParse(value);
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) => throw HTErr_Undefined(id);
}

class HT_ExternClass_Bool extends HT_ExternClass {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'parse':
        return (String? value) {
          return value.isNotEmpty;
        };
        break;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) => throw HTErr_Undefined(id);
}
