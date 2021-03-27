import 'dart:io';
import 'dart:math' as math;

import 'type.dart';
import 'errors.dart';
import 'object.dart';
import 'lexicon.dart';
import 'interpreter.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass extends HTObject {
  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  final String id;

  HTExternalClass(this.id);

  dynamic instanceMemberGet(dynamic instance, String varName) => throw HTErrorUndefined(varName);

  void instanceMemberSet(dynamic instance, String varName, dynamic value) => throw HTErrorUndefined(varName);

  dynamic instanceSubGet(dynamic instance, dynamic key) => throw HTErrorUndefined(key);

  void instanceSubSet(dynamic instance, dynamic key, dynamic value) => throw HTErrorUndefined(key);
}

class HTExternClassNumber extends HTExternalClass {
  HTExternClassNumber() : super(HTLexicon.number);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            num.tryParse(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassBool extends HTExternalClass {
  HTExternClassBool() : super(HTLexicon.boolean);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (
            [List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const <HTTypeId>[]]) {
          return (positionalArgs.first.toLowerCase() == 'true') ? true : false;
        };
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassString extends HTExternalClass {
  HTExternClassString() : super(HTLexicon.string);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'parse':
        return (
            [List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const <HTTypeId>[]]) {
          // TODO: 如果是脚本对象，需要调用脚本自己的toString
          return positionalArgs.first.toString();
        };
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassMath extends HTExternalClass {
  HTExternClassMath() : super(HTLexicon.math);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'random':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.Random().nextDouble();
      case 'randomInt':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.Random().nextInt(positionalArgs.first);
      case 'sqrt':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.sqrt(positionalArgs.first);
      case 'log':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.log(positionalArgs.first);
      case 'sin':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.sin(positionalArgs.first);
      case 'cos':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            math.cos(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassSystem extends HTExternalClass with InterpreterRef {
  HTExternClassSystem(Interpreter interpreter) : super(HTLexicon.system) {
    this.interpreter = interpreter;
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'invoke':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            interpreter.invoke(positionalArgs[0],
                positionalArgs: namedArgs['positionalArgs'], namedArgs: namedArgs['namedArgs']);
      case 'now':
        return DateTime.now().millisecondsSinceEpoch;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class HTExternClassConsole extends HTExternalClass {
  HTExternClassConsole() : super(HTLexicon.console);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'write':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            stdout.write(positionalArgs.first);
      case 'writeln':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            stdout.writeln(positionalArgs.first);
      case 'getln':
        return (
            [List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const <HTTypeId>[]]) {
          if (positionalArgs.isNotEmpty) {
            stdout.write('${positionalArgs.first}');
          } else {
            stdout.write('>');
          }
          return stdin.readLineSync();
        };
      case 'eraseLine':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      case 'setTitle':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            stdout.write('\x1b]0;${positionalArgs.first}\x07');
      case 'clear':
        return (
                [List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]]) =>
            stdout.write('\x1B[2J\x1B[0;0H');
      default:
        throw HTErrorUndefined(varName);
    }
  }
}
