import 'dart:io';
import 'dart:math' as math;

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/src/interpreter.dart';

import 'class.dart';
import 'type.dart';
import 'errors.dart';
import 'object.dart';

typedef HT_ExternFunc = dynamic Function(List<dynamic> positionalArgs, Map<String, dynamic> namedArgs);

abstract class HT_Extern_Global {
  static const number = 'num';
  static const boolean = 'bool';
  static const string = 'String';
  static const math = 'Math';
  static const system = 'System';
  static const console = 'Console';

  static Map<String, Function> functions = {
    'typeof': (dynamic value) => HT_TypeOf(value).toString(),
    'help': (dynamic value) {
      if (value is HT_Instance) {
        return value.typeid.toString();
      } else {
        return HT_TypeOf(value).toString();
      }
    },
    '_print': (List items) {
      var sb = StringBuffer();
      for (final item in items) {
        sb.write('${item.toString()} ');
      }
      print(sb.toString());
    },
    'string': (List items) {
      var result = StringBuffer();
      for (final item in items) {
        result.write(item.toString());
      }
      return result.toString();
    }
  };
}

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_ExternClass extends HT_Object {
  @override
  final HT_TypeId typeid = HT_TypeId.CLASS;
}

class HT_ExternClass_Number extends HT_ExternClass {
  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'parse':
        return (String value) => num.tryParse(value);
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}

class HT_ExternClass_Bool extends HT_ExternClass {
  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'parse':
        return (String value) {
          return (value.toLowerCase() == 'true') ? true : false;
        };
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}

class HT_ExternClass_String extends HT_ExternClass {
  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'parse':
        return (dynamic value) {
          // TODO: 如果是脚本对象，需要调用脚本自己的toString
          return value.toString();
        };
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}

class HT_ExternClass_Math extends HT_ExternClass {
  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'random':
        return () => math.Random().nextDouble();
      case 'randomInt':
        return (int max) => math.Random().nextInt(max);
      case 'sqrt':
        return (num x) => math.sqrt(x);
      case 'log':
        return (num x) => math.log(x);
      case 'sin':
        return (num x) => math.sin(x);
      case 'cos':
        return (num x) => math.cos(x);
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}

class HT_ExternClass_System extends HT_ExternClass with InterpreterRef {
  HT_ExternClass_System(Interpreter interpreter) {
    this.interpreter = interpreter;
  }

  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'invoke':
        return (String functionName,
                {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) =>
            interpreter.invoke(functionName, positionalArgs: positionalArgs, namedArgs: namedArgs);
      case 'now':
        return () => DateTime.now().millisecondsSinceEpoch;
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}

class HT_ExternClass_Console extends HT_ExternClass {
  @override
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'write':
        return (dynamic value) => stdout.write(value);
      case 'writeln':
        return ([dynamic value = '']) => stdout.writeln(value);
      case 'getln':
        return ([String value = '']) {
          if (value.isNotEmpty) {
            stdout.write('$value');
          } else {
            stdout.write('>');
          }
          return stdin.readLineSync();
        };
      case 'eraseLine':
        return () => stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      case 'setTitle':
        return (String title) => stdout.write('\x1b]0;$title\x07');
      case 'clear':
        return () => stdout.write('\x1B[2J\x1B[0;0H');
      default:
        throw HT_Error_Undefined(varName);
    }
  }
}
