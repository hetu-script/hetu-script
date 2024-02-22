import 'dart:math' as math;

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

class HTNumberClassBinding extends HTExternalClass {
  HTNumberClassBinding() : super('num');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'num.parse':
        return ({positionalArgs, namedArgs}) =>
            num.tryParse(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTIntClassBinding extends HTExternalClass {
  HTIntClassBinding() : super('int');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'int.fromEnvironment':
        return ({positionalArgs, namedArgs}) => int.fromEnvironment(
            positionalArgs[0],
            defaultValue: namedArgs['defaultValue']);
      case 'int.parse':
        return ({positionalArgs, namedArgs}) =>
            int.tryParse(positionalArgs[0], radix: namedArgs['radix']);
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as int).htFetch(id);
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
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as int).htFetch(id);
}

class HTFloatClassBinding extends HTExternalClass {
  HTFloatClassBinding() : super('float');

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
  dynamic instanceMemberGet(dynamic instance, String id) =>
      (instance as double).htFetch(id);
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
  HTStringClassBinding() : super('str');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'str.parse':
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

class HTHashClassBinding extends HTExternalClass {
  HTHashClassBinding() : super('Hash');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Hash.uid4':
        return ({positionalArgs, namedArgs}) {
          return uid4(positionalArgs.first);
        };
      case 'Hash.crcString':
        return ({positionalArgs, namedArgs}) {
          String data = positionalArgs[0];
          int crc = positionalArgs[1] ?? 0;
          return crcString(data, crc);
        };
      case 'Hash.crcInt':
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

class HTSystemClassBinding extends HTExternalClass {
  HTSystemClassBinding() : super('OS');

  @override
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'OS.now':
        return DateTime.now().millisecondsSinceEpoch;
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
