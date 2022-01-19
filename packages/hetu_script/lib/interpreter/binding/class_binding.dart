part of '../abstract_interpreter.dart';

class HTHetuClass extends HTExternalClass {
  HTHetuClass() : super('Hetu');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTNumberClassBinding extends HTExternalClass {
  HTNumberClassBinding() : super('num');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTIntClassBinding extends HTExternalClass {
  HTIntClassBinding() : super('int');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTBigIntClassBinding extends HTExternalClass {
  HTBigIntClassBinding() : super('BigInt');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'BigInt.zero':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            BigInt.zero;
      case 'BigInt.one':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            BigInt.one;
      case 'BigInt.two':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            BigInt.two;
      case 'BigInt.parse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            BigInt.tryParse(positionalArgs.first, radix: namedArgs['radix']);
      case 'BigInt.from':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            BigInt.from(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as int).htFetch(varName);
}

class HTFloatClassBinding extends HTExternalClass {
  HTFloatClassBinding() : super('float');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTBooleanClassBinding extends HTExternalClass {
  HTBooleanClassBinding() : super('bool');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTStringClassBinding extends HTExternalClass {
  HTStringClassBinding() : super('str');

  @override
  dynamic memberGet(String varName, {String? from}) {
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

class HTIteratorClassBinding extends HTExternalClass {
  HTIteratorClassBinding() : super('Iterator');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Iterator).htFetch(varName);
}

class HTIterableClassBinding extends HTExternalClass {
  HTIterableClassBinding() : super('Iterable');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Iterable).htFetch(varName);
}

class HTListClassBinding extends HTExternalClass {
  HTListClassBinding() : super('List');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'List':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            List.from(positionalArgs);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as List).htFetch(varName);
}

class HTSetClassBinding extends HTExternalClass {
  HTSetClassBinding() : super('Set');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Set':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Set.from(positionalArgs);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Set).htFetch(varName);
}

class HTMapClassBinding extends HTExternalClass {
  HTMapClassBinding() : super('Map');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Map':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            {};
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Map).htFetch(varName);
}

class HTMathClassBinding extends HTExternalClass {
  HTMathClassBinding() : super('Math');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Math.e':
        return math.e;
      case 'Math.pi':
        return math.pi;
      case 'Math.radiusToSigma':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            radiusToSigma(positionalArgs.first);
      case 'Math.gaussianNoise':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gaussianNoise(positionalArgs[0], positionalArgs[1]);
      case 'Math.perlinNoise':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            perlinNoise(positionalArgs[0], positionalArgs[1]);
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
      case 'Math.randomColorHex':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            '#' +
            (math.Random().nextDouble() * 16777215)
                .truncate()
                .toRadixString(16)
                .padLeft(6, '0');
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
                radix: namedArgs['radix']) ??
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

class HTHashClassBinding extends HTExternalClass {
  HTHashClassBinding() : super('Hash');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'Hash.uid4':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return uid4(positionalArgs.first);
        };
      case 'Hash.crc32b':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          String data = positionalArgs[0];
          int crc = positionalArgs[1] ?? 0;
          return crc32b(data, crc);
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTSystemClassBinding extends HTExternalClass {
  HTSystemClassBinding() : super('OS');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case 'System.now':
        return DateTime.now().millisecondsSinceEpoch;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTFutureClassBinding extends HTExternalClass {
  HTFutureClassBinding() : super('Future');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) =>
      (object as Future).htFetch(varName);
}
