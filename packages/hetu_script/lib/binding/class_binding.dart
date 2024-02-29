import 'dart:math' as math;
import 'dart:convert';

import 'package:fast_noise/fast_noise.dart';

import '../external/external_class.dart';
// import '../value/object.dart';
// import '../type/type.dart';
import '../error/error.dart';
import 'instance_binding.dart';
import '../utils/gaussian_noise.dart';
import '../utils/math.dart';
import '../utils/uid.dart';
import '../utils/crc32b.dart';
import '../value/function/function.dart';
import '../preinclude/console.dart';
import '../utils/jsonify.dart';
import '../lexicon/lexicon.dart';
import '../value/struct/struct.dart';
import '../locale/locale.dart';

class HTNumberClassBinding extends HTExternalClass {
  HTNumberClassBinding() : super('number');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'number.parse':
        return ({positionalArgs, namedArgs}) =>
            num.tryParse(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final object = instance as num;
    switch (id) {
      case 'toPercentageString':
        return ({positionalArgs, namedArgs}) {
          final fractionDigits = positionalArgs.first;
          return (object * 100).toStringAsFixed(fractionDigits).toString() +
              HTLocale.current.percentageMark;
        };
      case 'compareTo':
        return ({positionalArgs, namedArgs}) =>
            object.compareTo(positionalArgs[0]);
      case 'remainder':
        return ({positionalArgs, namedArgs}) =>
            object.remainder(positionalArgs[0]);
      case 'isNaN':
        return object.isNaN;
      case 'isNegative':
        return object.isNegative;
      case 'isInfinite':
        return object.isInfinite;
      case 'isFinite':
        return object.isFinite;
      case 'abs':
        return ({positionalArgs, namedArgs}) => object.abs();
      case 'sign':
        return object.sign;
      case 'round':
        return ({positionalArgs, namedArgs}) => object.round();
      case 'floor':
        return ({positionalArgs, namedArgs}) => object.floor();
      case 'ceil':
        return ({positionalArgs, namedArgs}) => object.ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs}) => object.truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs}) => object.roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs}) => object.floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs}) => object.ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs}) => object.truncateToDouble();
      case 'toInt':
        return ({positionalArgs, namedArgs}) => object.toInt();
      case 'toDouble':
        return ({positionalArgs, namedArgs}) => object.toDouble();
      case 'toStringAsFixed':
        return ({positionalArgs, namedArgs}) =>
            object.toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({positionalArgs, namedArgs}) =>
            object.toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({positionalArgs, namedArgs}) =>
            object.toStringAsPrecision(positionalArgs[0]);
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTIntegerClassBinding extends HTExternalClass {
  HTIntegerClassBinding({required super.superClass}) : super('integer');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'integer.fromEnvironment':
        return ({positionalArgs, namedArgs}) => int.fromEnvironment(
            positionalArgs[0],
            defaultValue: namedArgs['defaultValue']);
      case 'integer.parse':
        return ({positionalArgs, namedArgs}) =>
            int.tryParse(positionalArgs[0], radix: namedArgs['radix']);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final object = instance as int;
    switch (id) {
      case 'modPow':
        return ({positionalArgs, namedArgs}) =>
            object.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({positionalArgs, namedArgs}) =>
            object.modInverse(positionalArgs[0]);
      case 'gcd':
        return ({positionalArgs, namedArgs}) => object.gcd(positionalArgs[0]);
      case 'isEven':
        return object.isEven;
      case 'isOdd':
        return object.isOdd;
      case 'bitLength':
        return object.bitLength;
      case 'toUnsigned':
        return ({positionalArgs, namedArgs}) =>
            object.toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return ({positionalArgs, namedArgs}) =>
            object.toSigned(positionalArgs[0]);
      case 'toRadixString':
        return ({positionalArgs, namedArgs}) =>
            object.toRadixString(positionalArgs[0]);
      default:
        return superClass?.instanceMemberGet(instance, id);
    }
  }
}

class HTBigIntClassBinding extends HTExternalClass {
  HTBigIntClassBinding() : super('BigInt');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'BigInt.zero':
        return ({positionalArgs, namedArgs}) => BigInt.zero;
      case 'BigInt.one':
        return ({positionalArgs, namedArgs}) => BigInt.one;
      case 'BigInt.two':
        return ({positionalArgs, namedArgs}) => BigInt.two;
      case 'BigInt.parse':
        return ({positionalArgs, namedArgs}) =>
            BigInt.tryParse(positionalArgs.first, radix: namedArgs['radix']);
      case 'BigInt.from':
        return ({positionalArgs, namedArgs}) =>
            BigInt.from(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final object = instance as BigInt;
    switch (id) {
      case 'bitLength':
        return object.bitLength;
      case 'sign':
        return object.sign;
      case 'isEven':
        return object.isEven;
      case 'isOdd':
        return object.isOdd;
      case 'isNegative':
        return object.isNegative;
      case 'pow':
        return ({positionalArgs, namedArgs}) =>
            object.pow(positionalArgs.first);
      case 'modPow':
        return ({positionalArgs, namedArgs}) =>
            object.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({positionalArgs, namedArgs}) =>
            object.modInverse(positionalArgs.first);
      case 'gcd':
        return ({positionalArgs, namedArgs}) =>
            object.gcd(positionalArgs.first);
      case 'toUnsigned':
        return ({positionalArgs, namedArgs}) =>
            object.toUnsigned(positionalArgs.first);
      case 'toSigned':
        return ({positionalArgs, namedArgs}) =>
            object.toSigned(positionalArgs.first);
      case 'isValidInt':
        return object.isValidInt;
      case 'toInt':
        return ({positionalArgs, namedArgs}) => object.toInt();
      case 'toDouble':
        return ({positionalArgs, namedArgs}) => object.toDouble();
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      case 'toRadixString':
        return ({positionalArgs, namedArgs}) =>
            object.toRadixString(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTFloatClassBinding extends HTExternalClass {
  HTFloatClassBinding({required super.superClass}) : super('float');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
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
        return ({positionalArgs, namedArgs}) =>
            double.tryParse(positionalArgs[0]);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    final object = instance as double;
    switch (id) {
      case 'toDoubleAsFixed':
        return ({positionalArgs, namedArgs}) =>
            double.parse(object.toStringAsFixed(positionalArgs.first));
      default:
        return superClass?.instanceMemberGet(instance, id);
    }
  }
}

class HTBooleanClassBinding extends HTExternalClass {
  HTBooleanClassBinding() : super('bool');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'bool.parse':
        return ({positionalArgs, namedArgs}) {
          return (positionalArgs.first.toLowerCase() == 'true') ? true : false;
        };
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTStringClassBinding extends HTExternalClass {
  HTStringClassBinding() : super('string');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'string.parse':
        return ({positionalArgs, namedArgs}) {
          return positionalArgs.first.toString();
        };
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as String).htFetch(id);
}

class HTIteratorClassBinding extends HTExternalClass {
  HTIteratorClassBinding() : super('Iterator');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as Iterator).htFetch(id);
}

class HTIterableClassBinding extends HTExternalClass {
  HTIterableClassBinding() : super('Iterable');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as Iterable).htFetch(id);
}

class HTListClassBinding extends HTExternalClass {
  HTListClassBinding() : super('List');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'List':
        return ({positionalArgs, namedArgs}) => List.from(positionalArgs);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as List).htFetch(id);
}

class HTSetClassBinding extends HTExternalClass {
  HTSetClassBinding() : super('Set');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Set':
        return ({positionalArgs, namedArgs}) => Set.from(positionalArgs);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as Set).htFetch(id);
}

class HTMapClassBinding extends HTExternalClass {
  HTMapClassBinding() : super('Map');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Map':
        return ({positionalArgs, namedArgs}) => {};
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as Map).htFetch(id);
}

class HTRandomClassBinding extends HTExternalClass {
  HTRandomClassBinding() : super('Random');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Random':
        return ({positionalArgs, namedArgs}) =>
            math.Random(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as math.Random).htFetch(id);
}

class HTMathClassBinding extends HTExternalClass {
  HTMathClassBinding() : super('Math');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Math.e':
        return math.e;
      case 'Math.pi':
        return math.pi;
      case 'Math.degrees':
        return ({positionalArgs, namedArgs}) =>
            degrees(positionalArgs.first.toDouble());
      case 'Math.radians':
        return ({positionalArgs, namedArgs}) =>
            radians(positionalArgs.first.toDouble());
      case 'Math.radiusToSigma':
        return ({positionalArgs, namedArgs}) =>
            radiusToSigma(positionalArgs.first.toDouble());
      case 'Math.gaussianNoise':
        return ({positionalArgs, namedArgs}) {
          final mean = positionalArgs[0].toDouble();
          final standardDeviation = positionalArgs[1].toDouble();
          final math.Random? randomGenerator = namedArgs['randomGenerator'];
          assert(standardDeviation > 0);
          final num? min = namedArgs['min'];
          final num? max = namedArgs['max'];
          double r;
          do {
            r = gaussianNoise(
              mean,
              standardDeviation,
              randomGenerator: randomGenerator,
            );
          } while ((min != null && r < min) || (max != null && r > max));
          return r;
        };
      case 'Math.noise2d':
        return ({positionalArgs, namedArgs}) {
          final int size = positionalArgs[0].toInt();
          final seed = namedArgs['seed'] ?? math.Random().nextInt(1 << 32);
          final frequency = namedArgs['frequency'];
          final noiseTypeString = namedArgs['noiseType'];
          NoiseType noiseType;
          switch (noiseTypeString) {
            case 'perlinFractal':
              noiseType = NoiseType.perlinFractal;
            case 'perlin':
              noiseType = NoiseType.perlin;
            case 'cubicFractal':
              noiseType = NoiseType.cubicFractal;
            case 'cubic':
            default:
              noiseType = NoiseType.cubic;
          }
          return noise2(
            size,
            size,
            seed: seed,
            frequency: frequency,
            noiseType: noiseType,
          );
        };
      case 'Math.min':
        return ({positionalArgs, namedArgs}) {
          if (positionalArgs[0] == null) {
            return positionalArgs[1];
          }
          if (positionalArgs[1] == null) {
            return positionalArgs[0];
          }
          return math.min(positionalArgs[0] as num, positionalArgs[1] as num);
        };
      case 'Math.max':
        return ({positionalArgs, namedArgs}) {
          if (positionalArgs[0] == null) {
            return positionalArgs[1];
          }
          if (positionalArgs[1] == null) {
            return positionalArgs[0];
          }
          return math.max(positionalArgs[0] as num, positionalArgs[1] as num);
        };
      case 'Math.sqrt':
        return ({positionalArgs, namedArgs}) =>
            math.sqrt(positionalArgs.first as num);
      case 'Math.pow':
        return ({positionalArgs, namedArgs}) =>
            math.pow(positionalArgs[0] as num, positionalArgs[1] as num);
      case 'Math.sin':
        return ({positionalArgs, namedArgs}) =>
            math.sin(positionalArgs.first as num);
      case 'Math.cos':
        return ({positionalArgs, namedArgs}) =>
            math.cos(positionalArgs.first as num);
      case 'Math.tan':
        return ({positionalArgs, namedArgs}) =>
            math.tan(positionalArgs.first as num);
      case 'Math.exp':
        return ({positionalArgs, namedArgs}) =>
            math.exp(positionalArgs.first as num);
      case 'Math.log':
        return ({positionalArgs, namedArgs}) =>
            math.log(positionalArgs.first as num);
      case 'Math.parseInt':
        return ({positionalArgs, namedArgs}) =>
            int.tryParse(positionalArgs.first as String,
                radix: namedArgs['radix']) ??
            0;
      case 'Math.parseDouble':
        return ({positionalArgs, namedArgs}) =>
            double.tryParse(positionalArgs.first as String) ?? 0.0;
      case 'Math.sum':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs.first as List<num>)
                .reduce((value, element) => value + element);
      case 'Math.checkBit':
        return ({positionalArgs, namedArgs}) =>
            ((positionalArgs[0] as int) & (1 << (positionalArgs[1] as int))) !=
            0;
      case 'Math.bitLS':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs[0] as int) << (positionalArgs[1] as int);
      case 'Math.bitRS':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs[0] as int) >> (positionalArgs[1] as int);
      case 'Math.bitAnd':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs[0] as int) & (positionalArgs[1] as int);
      case 'Math.bitOr':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs[0] as int) | (positionalArgs[1] as int);
      case 'Math.bitNot':
        return ({positionalArgs, namedArgs}) => ~(positionalArgs[0] as int);
      case 'Math.bitXor':
        return ({positionalArgs, namedArgs}) =>
            (positionalArgs[0] as int) ^ (positionalArgs[1] as int);

      default:
        throw HTError.undefined(id);
    }
  }
}

class HTFutureClassBinding extends HTExternalClass {
  HTFutureClassBinding() : super('Future');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Future':
        return ({positionalArgs, namedArgs}) {
          final HTFunction func = positionalArgs.first;
          return Future(() => func.call());
        };
      case 'Future.wait':
        return ({positionalArgs, namedArgs}) {
          final futures = List<Future<dynamic>>.from(positionalArgs.first);
          // final HTFunction? func = namedArgs['cleanUp'];
          return Future.wait(futures);
          // , cleanUp: (value) {
          //   if (func != null) func.call(positionalArgs: [value]);
          // });
        };
      case 'Future.value':
        return ({positionalArgs, namedArgs}) {
          return Future.value(positionalArgs.first);
        };
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as Future).htFetch(id);
}

class HTCryptoClassBinding extends HTExternalClass {
  HTCryptoClassBinding() : super('crypto');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'crypto.randomUUID':
        return ({positionalArgs, namedArgs}) {
          return randomUUID();
        };
      case 'crypto.randomUID4':
        return ({positionalArgs, namedArgs}) {
          return randomUID4(positionalArgs.first);
        };
      case 'crypto.crcString':
        return ({positionalArgs, namedArgs}) {
          String data = positionalArgs[0];
          int crc = positionalArgs[1] ?? 0;
          return crcString(data, crc);
        };
      case 'crypto.crcInt':
        return ({positionalArgs, namedArgs}) {
          String data = positionalArgs[0];
          int crc = positionalArgs[1] ?? 0;
          return crcInt(data, crc);
        };
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTConsoleClassBinding extends HTExternalClass {
  Console console;

  HTConsoleClassBinding({required this.console}) : super('console');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'console.log':
        return ({positionalArgs, namedArgs}) => console.log(positionalArgs);
      case 'console.debug':
        return ({positionalArgs, namedArgs}) => console.debug(positionalArgs);
      case 'console.info':
        return ({positionalArgs, namedArgs}) => console.info(positionalArgs);
      case 'console.warn':
        return ({positionalArgs, namedArgs}) => console.warn(positionalArgs);
      case 'console.error':
        return ({positionalArgs, namedArgs}) => console.error(positionalArgs);
      case 'console.time':
        return ({positionalArgs, namedArgs}) =>
            console.time(positionalArgs.first);
      case 'console.timeLog':
        return ({positionalArgs, namedArgs}) =>
            console.timeLog(positionalArgs.first);
      case 'console.timeEnd':
        return ({positionalArgs, namedArgs}) =>
            console.timeEnd(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTJSONClassBinding extends HTExternalClass {
  HTLexicon lexicon;

  HTJSONClassBinding({required this.lexicon}) : super('JSON');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'JSON.stringify':
        return ({positionalArgs, namedArgs}) =>
            lexicon.stringify(positionalArgs.first);
      case 'JSON.parse':
        return ({positionalArgs, namedArgs}) {
          final object = positionalArgs.first;
          if (object is HTStruct) {
            return jsonifyStruct(object);
          } else if (object is Iterable) {
            return jsonifyList(object);
          } else if (isJsonDataType(object)) {
            return lexicon.stringify(object);
          } else {
            return jsonEncode(object);
          }
        };
      default:
        throw HTError.undefined(id);
    }
  }
}
