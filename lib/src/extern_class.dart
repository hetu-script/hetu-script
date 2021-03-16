import 'dart:io';
import 'dart:math' as math;

import 'type.dart';
import 'errors.dart';
import 'object.dart';
import 'lexicon.dart';
import 'interpreter.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternClass extends HTObject {
  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  final String id;

  HTExternClass(this.id);

  dynamic instanceFetch(dynamic instance, String varName) => throw HTErrorUndefined(varName);

  void instanceAssign(dynamic instance, String varName, dynamic value) => throw HTErrorUndefined(varName);
}

abstract class HTExternGlobal {
  static const number = 'num';
  static const boolean = 'bool';
  static const string = 'String';
  static const math = 'Math';
  static const system = 'System';
  static const console = 'Console';

  static Map<String, Function> functions = {
    'help': (dynamic value) {
      // TODO: 读取注释
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

class HTExternClassNumber extends HTExternClass {
  HTExternClassNumber() : super(HTLexicon.number);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (String value) => num.tryParse(value);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassBool extends HTExternClass {
  HTExternClassBool() : super(HTLexicon.boolean);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (String value) {
          return (value.toLowerCase() == 'true') ? true : false;
        };
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassString extends HTExternClass {
  HTExternClassString() : super(HTLexicon.string);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (dynamic value) {
          // TODO: 如果是脚本对象，需要调用脚本自己的toString
          return value.toString();
        };
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassMath extends HTExternClass {
  HTExternClassMath() : super(HTExternGlobal.math);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
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
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassSystem extends HTExternClass with InterpreterRef {
  HTExternClassSystem(Interpreter interpreter) : super(HTExternGlobal.system) {
    this.interpreter = interpreter;
  }

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'invoke':
        return (String functionName,
                {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) =>
            interpreter.invoke(functionName, positionalArgs: positionalArgs, namedArgs: namedArgs);
      case 'now':
        return () => DateTime.now().millisecondsSinceEpoch;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassConsole extends HTExternClass {
  HTExternClassConsole() : super(HTExternGlobal.console);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
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
        throw HTErrorUndefined(varName);
    }
  }
}
