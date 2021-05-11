import 'dart:io';
import 'dart:math' as math;

import '../type_system/type.dart';
import '../common/lexicon.dart';
import '../common/errors.dart';
import '../binding/external_class.dart';
import 'core_instance.dart';

class HTNumberClass extends HTExternalClass {
  HTNumberClass() : super(HTLexicon.number);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'num.parse':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            num.tryParse(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTIntegerClass extends HTExternalClass {
  HTIntegerClass() : super(HTLexicon.integer);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'int.fromEnvironment':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            int.fromEnvironment(positionalArgs[0],
                defaultValue: namedArgs['defaultValue']);
      case 'int.parse':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            int.tryParse(positionalArgs[0], radix: namedArgs['radix']);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as int).htFetch(varName);
}

class HTFloatClass extends HTExternalClass {
  HTFloatClass() : super(HTLexicon.float);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'float.nan':
        return double.nan;
      case 'float.infinity':
        return double.infinity;
      case 'float.negativeInfinity':
        return double.negativeInfinity;
      case 'float.minPositive':
        return double.minPositive;
      case 'float.maxFinite':
        return double.maxFinite;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as double).htFetch(varName);
}

class HTBooleanClass extends HTExternalClass {
  HTBooleanClass() : super(HTLexicon.boolean);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'bool.parse':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return (positionalArgs.first.toLowerCase() == 'true') ? true : false;
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTStringClass extends HTExternalClass {
  HTStringClass() : super(HTLexicon.string);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'str.parse':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return positionalArgs.first.toString();
        };
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as String).htFetch(varName);
}

class HTListClass extends HTExternalClass {
  HTListClass() : super(HTLexicon.list);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as List).htFetch(varName);
}

class HTMapClass extends HTExternalClass {
  HTMapClass() : super(HTLexicon.map);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Map).htFetch(varName);
}

class HTMathClass extends HTExternalClass {
  HTMathClass() : super(HTLexicon.math);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Math.e':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.e;
      case 'Math.pi':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.pi;
      case 'Math.min':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.min(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.max':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.max(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.random':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.Random().nextDouble();
      case 'Math.randomInt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.Random().nextInt(positionalArgs.first as int);
      case 'Math.sqrt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.sqrt(positionalArgs.first as num);
      case 'Math.pow':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.pow(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.sin':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.sin(positionalArgs.first as num);
      case 'Math.cos':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.cos(positionalArgs.first as num);
      case 'Math.tan':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.tan(positionalArgs.first as num);
      case 'Math.exp':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.exp(positionalArgs.first as num);
      case 'Math.log':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.log(positionalArgs.first as num);
      case 'Math.parseInt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            int.tryParse(positionalArgs.first as String,
                radix: namedArgs['radix'] as int) ??
            0;
      case 'Math.parseDouble':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            double.tryParse(positionalArgs.first as String) ?? 0.0;
      case 'Math.sum':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs.first as List<num>)
                .reduce((value, element) => value + element);
      case 'Math.checkBit':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ((positionalArgs[0] as int) & (1 << (positionalArgs[1] as int))) !=
            0;
      case 'Math.bitLS':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) << (positionalArgs[1] as int);
      case 'Math.bitRS':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) >> (positionalArgs[1] as int);
      case 'Math.bitAnd':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) & (positionalArgs[1] as int);
      case 'Math.bitOr':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) | (positionalArgs[1] as int);
      case 'Math.bitNot':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ~(positionalArgs[0] as int);
      case 'Math.bitXor':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) ^ (positionalArgs[1] as int);

      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTSystemClass extends HTExternalClass {
  HTSystemClass() : super(HTLexicon.system);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'System.now':
        return DateTime.now().millisecondsSinceEpoch;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTConsoleClass extends HTExternalClass {
  HTConsoleClass() : super(HTLexicon.console);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'Console.write':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            stdout.write(positionalArgs.first);
      case 'Console.writeln':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            stdout.writeln(positionalArgs.first);
      case 'Console.getln':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
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
                List<HTType> typeArgs = const []}) =>
            stdout.write('\x1B[1F\x1B[1G\x1B[1K');
      case 'Console.setTitle':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            stdout.write('\x1b]0;${positionalArgs.first}\x07');
      case 'Console.clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            stdout.write('\x1B[2J\x1B[0;0H');
      default:
        throw HTError.undefined(varName);
    }
  }
}
