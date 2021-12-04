part of '../abstract_interpreter.dart';

class HTNumberClass extends HTExternalClass {
  HTNumberClass() : super('num');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'num.parse':
        return (HTEntity entity,
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
  HTIntegerClass() : super('int');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'int.fromEnvironment':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            int.fromEnvironment(positionalArgs[0],
                defaultValue: namedArgs['defaultValue']);
      case 'int.parse':
        return (HTEntity entity,
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
  HTFloatClass() : super('float');

  @override
  dynamic memberGet(String varName) {
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
      case 'float.parse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            double.tryParse(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as double).htFetch(varName);
}

class HTBooleanClass extends HTExternalClass {
  HTBooleanClass() : super('bool');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'bool.parse':
        return (HTEntity entity,
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
  HTStringClass() : super('str');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'str.parse':
        return (HTEntity entity,
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
  HTListClass() : super('List');

  @override
  dynamic memberGet(String varName) {
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
  HTMapClass() : super('Map');

  @override
  dynamic memberGet(String varName) {
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
  HTMathClass() : super('Math');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'Math.e':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.e;
      case 'Math.pi':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.pi;
      case 'Math.min':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.min(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.max':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.max(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.random':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.Random().nextDouble();
      case 'Math.randomInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.Random().nextInt(positionalArgs.first as int);
      case 'Math.sqrt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.sqrt(positionalArgs.first as num);
      case 'Math.pow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.pow(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.sin':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.sin(positionalArgs.first as num);
      case 'Math.cos':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.cos(positionalArgs.first as num);
      case 'Math.tan':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.tan(positionalArgs.first as num);
      case 'Math.exp':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.exp(positionalArgs.first as num);
      case 'Math.log':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            math.log(positionalArgs.first as num);
      case 'Math.parseInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            int.tryParse(positionalArgs.first as String,
                radix: namedArgs['radix'] as int) ??
            0;
      case 'Math.parseDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            double.tryParse(positionalArgs.first as String) ?? 0.0;
      case 'Math.sum':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs.first as List<num>)
                .reduce((value, element) => value + element);
      case 'Math.checkBit':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ((positionalArgs[0] as int) & (1 << (positionalArgs[1] as int))) !=
            0;
      case 'Math.bitLS':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) << (positionalArgs[1] as int);
      case 'Math.bitRS':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) >> (positionalArgs[1] as int);
      case 'Math.bitAnd':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) & (positionalArgs[1] as int);
      case 'Math.bitOr':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            (positionalArgs[0] as int) | (positionalArgs[1] as int);
      case 'Math.bitNot':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ~(positionalArgs[0] as int);
      case 'Math.bitXor':
        return (HTEntity entity,
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
  HTSystemClass() : super('System');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'System.now':
        return DateTime.now().millisecondsSinceEpoch;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTFutureClass extends HTExternalClass {
  HTFutureClass() : super('Future');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Future).htFetch(varName);
}
