import 'dart:io';
import 'dart:math' as math;
import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'interpreter.dart';
import 'object.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass with HTObject {
  late final String typename;
  late final List<String> typeArgs;

  /// Default [HTExternalClass] constructor.
  HTExternalClass(this.typename, [this.typeArgs = const []]);
  // {
  //   typeid = HTTypeId.parse(typeString);
  // }

  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key
  /// ```
  dynamic instanceMemberGet(dynamic object, String varName) =>
      throw HTErrorUndefined(varName);

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key = value
  /// ```
  void instanceMemberSet(dynamic object, String varName, dynamic value) =>
      throw HTErrorUndefined(varName);

  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic instanceSubGet(dynamic object, dynamic key) => object[key];

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void instanceSubSet(dynamic object, dynamic key, dynamic value) =>
      object[key] = value;
}

class HTExternClassNumber extends HTExternalClass {
  HTExternClassNumber() : super(HTLexicon.number);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'num.parse':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
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
      case 'bool.parse':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) {
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
      case 'str.parse':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) {
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
      case 'Math.e':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.e;
      case 'Math.pi':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.pi;
      case 'Math.min':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.min(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.max':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.max(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.random':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.Random().nextDouble();
      case 'Math.randomInt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.Random().nextInt(positionalArgs.first as int);
      case 'Math.sqrt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.sqrt(positionalArgs.first as num);
      case 'Math.pow':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.pow(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.sin':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.sin(positionalArgs.first as num);
      case 'Math.cos':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.cos(positionalArgs.first as num);
      case 'Math.tan':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.tan(positionalArgs.first as num);
      case 'Math.exp':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.exp(positionalArgs.first as num);
      case 'Math.log':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            math.log(positionalArgs.first as num);
      case 'Math.parseInt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            int.tryParse(positionalArgs.first as String,
                radix: namedArgs['radix'] as int) ??
            0;
      case 'Math.parseDouble':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            double.tryParse(positionalArgs.first as String) ?? 0.0;
      case 'Math.sum':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs.first as List<num>)
                .reduce((value, element) => value + element);
      case 'Math.checkBit':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            ((positionalArgs[0] as int) & (1 << (positionalArgs[1] as int))) !=
            0;
      case 'Math.bitLS':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs[0] as int) << (positionalArgs[1] as int);
      case 'Math.bitRS':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs[0] as int) >> (positionalArgs[1] as int);
      case 'Math.bitAnd':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs[0] as int) & (positionalArgs[1] as int);
      case 'Math.bitOr':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs[0] as int) | (positionalArgs[1] as int);
      case 'Math.bitNot':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            ~(positionalArgs[0] as int);
      case 'Math.bitXor':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            (positionalArgs[0] as int) ^ (positionalArgs[1] as int);

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
      case 'System.now':
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
      case 'Console.write':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            stdout.write(positionalArgs.first);
      case 'Console.writeln':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            stdout.writeln(positionalArgs.first);
      case 'Console.getln':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) {
          if (positionalArgs.isNotEmpty) {
            stdout.write('${positionalArgs.first}');
          } else {
            stdout.write('>');
          }
          return stdin.readLineSync();
        };
      case 'Console.eraseLine':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      case 'Console.setTitle':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            stdout.write('\x1b]0;${positionalArgs.first}\x07');
      case 'Console.clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            stdout.write('\x1B[2J\x1B[0;0H');
      default:
        throw HTErrorUndefined(varName);
    }
  }
}
