import 'dart:math' as math;
import 'dart:convert';
import 'dart:collection';

import 'package:characters/characters.dart';
import 'package:hetu_script/utils/math.dart';

import '../external/external_class.dart';
// import '../value/object.dart';
// import '../type/type.dart';
import '../error/error.dart';
import '../utils/uid.dart';
import '../utils/crc32b.dart';
import '../value/function/function.dart';
import '../preinclude/console.dart';
import '../utils/json.dart';
import '../lexicon/lexicon.dart';
// import '../value/struct/struct.dart';
import '../locale/locale.dart';
import '../utils/collection.dart';
// import '../utils/math.dart';

class HTNumberClassBinding extends HTExternalClass {
  HTNumberClassBinding() : super('number');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'number.parse':
        return ({positionalArgs, namedArgs}) =>
            num.tryParse(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'toPercentageString':
        return ({object, positionalArgs, namedArgs}) {
          final fractionDigits = positionalArgs.first;
          return (object * 100).toStringAsFixed(fractionDigits).toString() +
              HTLocale.current.percentageMark;
        };
      case 'compareTo':
        return ({object, positionalArgs, namedArgs}) =>
            object.compareTo(positionalArgs[0]);
      case 'remainder':
        return ({object, positionalArgs, namedArgs}) =>
            object.remainder(positionalArgs[0]);
      case 'isNaN':
        return instance.isNaN;
      case 'isNegative':
        return instance.isNegative;
      case 'isInfinite':
        return instance.isInfinite;
      case 'isFinite':
        return instance.isFinite;
      case 'abs':
        return ({object, positionalArgs, namedArgs}) => object.abs();
      case 'sign':
        return instance.sign;
      case 'round':
        return ({object, positionalArgs, namedArgs}) => object.round();
      case 'floor':
        return ({object, positionalArgs, namedArgs}) => object.floor();
      case 'ceil':
        return ({object, positionalArgs, namedArgs}) => object.ceil();
      case 'truncate':
        return ({object, positionalArgs, namedArgs}) => object.truncate();
      case 'roundToDouble':
        return ({object, positionalArgs, namedArgs}) => object.roundToDouble();
      case 'floorToDouble':
        return ({object, positionalArgs, namedArgs}) => object.floorToDouble();
      case 'ceilToDouble':
        return ({object, positionalArgs, namedArgs}) => object.ceilToDouble();
      case 'truncateToDouble':
        return ({object, positionalArgs, namedArgs}) =>
            object.truncateToDouble();
      case 'toInt':
        return ({object, positionalArgs, namedArgs}) => object.toInt();
      case 'toDouble':
        return ({object, positionalArgs, namedArgs}) => object.toDouble();
      case 'toStringAsFixed':
        return ({object, positionalArgs, namedArgs}) =>
            object.toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({object, positionalArgs, namedArgs}) =>
            object.toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({object, positionalArgs, namedArgs}) =>
            object.toStringAsPrecision(positionalArgs[0]);
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTIntegerClassBinding extends HTExternalClass {
  HTIntegerClassBinding({required super.superClass}) : super('integer');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'integer.fromEnvironment':
        return ({positionalArgs, namedArgs}) => int.fromEnvironment(
            positionalArgs[0],
            defaultValue: namedArgs['defaultValue']);
      case 'integer.parse':
        return ({positionalArgs, namedArgs}) =>
            int.tryParse(positionalArgs[0], radix: namedArgs['radix']);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'modPow':
        return ({object, positionalArgs, namedArgs}) =>
            object.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({object, positionalArgs, namedArgs}) =>
            object.modInverse(positionalArgs[0]);
      case 'gcd':
        return ({object, positionalArgs, namedArgs}) =>
            object.gcd(positionalArgs[0]);
      case 'isEven':
        return instance.isEven;
      case 'isOdd':
        return instance.isOdd;
      case 'bitLength':
        return instance.bitLength;
      case 'toUnsigned':
        return ({object, positionalArgs, namedArgs}) =>
            object.toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return ({object, positionalArgs, namedArgs}) =>
            object.toSigned(positionalArgs[0]);
      case 'toRadixString':
        return ({object, positionalArgs, namedArgs}) =>
            object.toRadixString(positionalArgs[0]);
      default:
        return superClass?.instanceMemberGet(instance, id);
    }
  }
}

class HTBigIntClassBinding extends HTExternalClass {
  HTBigIntClassBinding() : super('BigInt');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'BigInt.zero':
        return BigInt.zero;
      case 'BigInt.one':
        return BigInt.one;
      case 'BigInt.two':
        return BigInt.two;
      case 'BigInt.parse':
        return ({positionalArgs, namedArgs}) =>
            BigInt.tryParse(positionalArgs.first, radix: namedArgs['radix']);
      case 'BigInt.from':
        return ({positionalArgs, namedArgs}) =>
            BigInt.from(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'bitLength':
        return instance.bitLength;
      case 'sign':
        return instance.sign;
      case 'isEven':
        return instance.isEven;
      case 'isOdd':
        return instance.isOdd;
      case 'isNegative':
        return instance.isNegative;
      case 'pow':
        return ({object, positionalArgs, namedArgs}) =>
            object.pow(positionalArgs.first);
      case 'modPow':
        return ({object, positionalArgs, namedArgs}) =>
            object.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({object, positionalArgs, namedArgs}) =>
            object.modInverse(positionalArgs.first);
      case 'gcd':
        return ({object, positionalArgs, namedArgs}) =>
            object.gcd(positionalArgs.first);
      case 'toUnsigned':
        return ({object, positionalArgs, namedArgs}) =>
            object.toUnsigned(positionalArgs.first);
      case 'toSigned':
        return ({object, positionalArgs, namedArgs}) =>
            object.toSigned(positionalArgs.first);
      case 'isValidInt':
        return instance.isValidInt;
      case 'toInt':
        return ({object, positionalArgs, namedArgs}) => object.toInt();
      case 'toDouble':
        return ({object, positionalArgs, namedArgs}) => object.toDouble();
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      case 'toRadixString':
        return ({object, positionalArgs, namedArgs}) =>
            object.toRadixString(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class HTFloatClassBinding extends HTExternalClass {
  HTFloatClassBinding({required super.superClass}) : super('float');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
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
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'toDoubleAsFixed':
        return ({object, positionalArgs, namedArgs}) =>
            double.parse(object.toStringAsFixed(positionalArgs.first));
      default:
        return superClass?.instanceMemberGet(instance, id);
    }
  }
}

class HTBooleanClassBinding extends HTExternalClass {
  HTBooleanClassBinding() : super('bool');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'bool.parse':
        return ({positionalArgs, namedArgs}) {
          return (positionalArgs.first.toLowerCase() == 'true') ? true : false;
        };
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class HTStringClassBinding extends HTExternalClass {
  HTStringClassBinding() : super('string');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'string.parse':
        return ({positionalArgs, namedArgs}) => positionalArgs.first.toString();
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'characters':
        return ({object, positionalArgs, namedArgs}) => Characters(object);
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      case 'compareTo':
        return ({object, positionalArgs, namedArgs}) =>
            object.compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return ({object, positionalArgs, namedArgs}) =>
            object.codeUnitAt(positionalArgs[0]);
      case 'length':
        return instance.length;
      case 'endsWith':
        return ({object, positionalArgs, namedArgs}) =>
            object.endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({object, positionalArgs, namedArgs}) =>
            object.startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({object, positionalArgs, namedArgs}) =>
            object.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({object, positionalArgs, namedArgs}) =>
            object.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return instance.isEmpty;
      case 'isNotEmpty':
        return instance.isNotEmpty;
      case 'substring':
        return ({object, positionalArgs, namedArgs}) =>
            object.substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({object, positionalArgs, namedArgs}) => object.trim();
      case 'trimLeft':
        return ({object, positionalArgs, namedArgs}) => object.trimLeft();
      case 'trimRight':
        return ({object, positionalArgs, namedArgs}) => object.trimRight();
      case 'padLeft':
        return ({object, positionalArgs, namedArgs}) =>
            object.padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({object, positionalArgs, namedArgs}) =>
            object.padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({object, positionalArgs, namedArgs}) =>
            object.contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({object, positionalArgs, namedArgs}) => object.replaceFirst(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({object, positionalArgs, namedArgs}) => object.replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({object, positionalArgs, namedArgs}) =>
            object.split(positionalArgs[0]);
      case 'toLowerCase':
        return ({object, positionalArgs, namedArgs}) => object.toLowerCase();
      case 'toUpperCase':
        return ({object, positionalArgs, namedArgs}) => object.toUpperCase();
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTIteratorClassBinding extends HTExternalClass {
  HTIteratorClassBinding() : super('Iterator');

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'moveNext':
        return ({object, positionalArgs, namedArgs}) => object.moveNext();
      case 'current':
        return instance.current;
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTIterableClassBinding extends HTExternalClass {
  HTIterableClassBinding() : super('Iterable');

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      case 'toJSON':
        return ({object, positionalArgs, namedArgs}) => jsonifyList(object);
      case 'random':
        final random = math.Random();
        if (instance.isNotEmpty) {
          return instance.elementAt(random.nextInt(instance.length));
        } else {
          return null;
        }
      case 'iterator':
        return instance.iterator;
      case 'map':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.map((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'where':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.where((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'expand':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return instance.expand((element) {
            return func.call(positionalArgs: [element]) as Iterable;
          });
        };
      case 'contains':
        return ({object, positionalArgs, namedArgs}) =>
            object.contains(positionalArgs.first);
      case 'reduce':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.reduce((value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'fold':
        return ({object, positionalArgs, namedArgs}) {
          final initialValue = positionalArgs[0];
          HTFunction func = positionalArgs[1];
          return object.fold(initialValue, (value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'every':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.every((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'join':
        return ({object, positionalArgs, namedArgs}) =>
            object.join(positionalArgs.first);
      case 'any':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.any((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'toList':
        return ({object, positionalArgs, namedArgs}) => object.toList();
      case 'length':
        return instance.length;
      case 'isEmpty':
        return instance.isEmpty;
      case 'isNotEmpty':
        return instance.isNotEmpty;
      case 'take':
        return ({object, positionalArgs, namedArgs}) =>
            object.take(positionalArgs.first);
      case 'takeWhile':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.takeWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'skip':
        return ({object, positionalArgs, namedArgs}) =>
            object.skip(positionalArgs.first);
      case 'skipWhile':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.skipWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'first':
        return instance.isNotEmpty ? instance.first : null;
      case 'last':
        return instance.isNotEmpty ? instance.last : null;
      case 'single':
        return instance.single;
      case 'firstWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.firstWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'lastWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.lastWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'singleWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.singleWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'elementAt':
        return ({object, positionalArgs, namedArgs}) =>
            object.elementAt(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTListClassBinding extends HTExternalClass {
  HTListClassBinding({required super.superClass}) : super('List');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'List':
        return ({positionalArgs, namedArgs}) => List.from(positionalArgs);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'addIfAbsent':
        return ({object, positionalArgs, namedArgs}) {
          if (!object.contains(positionalArgs.first)) {
            object.add(positionalArgs.first);
          }
        };
      case 'add':
        return ({object, positionalArgs, namedArgs}) {
          object.add(positionalArgs.first);
        };
      case 'addAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'reversed':
        return instance.reversed;
      case 'indexOf':
        return ({object, positionalArgs, namedArgs}) =>
            object.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({object, positionalArgs, namedArgs}) =>
            object.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return ({object, positionalArgs, namedArgs}) =>
            object.insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return ({object, positionalArgs, namedArgs}) => object.clear();
      case 'remove':
        return ({object, positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      case 'removeAt':
        return ({object, positionalArgs, namedArgs}) =>
            object.removeAt(positionalArgs.first);
      case 'removeLast':
        return ({object, positionalArgs, namedArgs}) => object.removeLast();
      case 'removeFirst':
        return ({object, positionalArgs, namedArgs}) => object.removeAt(0);
      case 'sublist':
        return ({object, positionalArgs, namedArgs}) =>
            object.sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return ({object, positionalArgs, namedArgs}) => object.asMap();
      case 'sort':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction? func = positionalArgs.first;
          int Function(dynamic, dynamic)? sortFunc;
          if (func != null) {
            sortFunc = (a, b) {
              return func.call(positionalArgs: [a, b]) as int;
            };
          }
          object.sort(sortFunc);
        };
      case 'shuffle':
        return ({object, positionalArgs, namedArgs}) => object.shuffle();
      case 'indexWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int start = positionalArgs[1];
          return object.indexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'lastIndexWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int? start = positionalArgs[1];
          return object.lastIndexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'removeWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'getRange':
        return ({object, positionalArgs, namedArgs}) =>
            object.getRange(positionalArgs[0], positionalArgs[1]);
      case 'setRange':
        return ({object, positionalArgs, namedArgs}) => object.setRange(
            positionalArgs[0],
            positionalArgs[1],
            positionalArgs[2],
            positionalArgs[3]);
      case 'removeRange':
        return ({object, positionalArgs, namedArgs}) =>
            object.removeRange(positionalArgs[0], positionalArgs[1]);
      case 'fillRange':
        return ({object, positionalArgs, namedArgs}) => object.fillRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceRange':
        return ({object, positionalArgs, namedArgs}) => object.replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'clone':
        return ({object, positionalArgs, namedArgs}) => deepCopy(object);
      default:
        return superClass!.instanceMemberGet(instance, id);
    }
  }

  @override
  void instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'first':
        ({object, positionalArgs, namedArgs}) => object.first = value;
      case 'last':
        ({object, positionalArgs, namedArgs}) => object.last = value;
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTSetClassBinding extends HTExternalClass {
  HTSetClassBinding({required super.superClass}) : super('Set');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Set':
        return ({positionalArgs, namedArgs}) =>
            Set.from(positionalArgs.first ?? []);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      case 'add':
        return ({object, positionalArgs, namedArgs}) =>
            object.add(positionalArgs.first);
      case 'addAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'remove':
        return ({object, positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      case 'lookup':
        return ({object, positionalArgs, namedArgs}) =>
            object.lookup(positionalArgs[0]);
      case 'removeAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.removeAll(positionalArgs.first);
      case 'retainAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.retainAll(positionalArgs.first);
      case 'removeWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'containsAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.containsAll(positionalArgs.first);
      case 'intersection':
        return ({object, positionalArgs, namedArgs}) =>
            object.intersection(positionalArgs.first);
      case 'union':
        return ({object, positionalArgs, namedArgs}) =>
            object.union(positionalArgs.first);
      case 'difference':
        return ({object, positionalArgs, namedArgs}) =>
            object.difference(positionalArgs.first);
      case 'clear':
        return ({object, positionalArgs, namedArgs}) => object.clear();
      case 'toSet':
        return ({object, positionalArgs, namedArgs}) => object.toSet();
      default:
        return superClass!.instanceMemberGet(instance, id);
    }
  }
}

class HTMapClassBinding extends HTExternalClass {
  HTMapClassBinding() : super('Map');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Map':
        return ({positionalArgs, namedArgs}) => {};
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'toString':
        return ({object, positionalArgs, namedArgs}) => object.toString();
      case 'length':
        return instance.length;
      case 'isEmpty':
        return instance.isEmpty;
      case 'isNotEmpty':
        return instance.isNotEmpty;
      case 'keys':
        return instance.keys;
      case 'values':
        return instance.values;
      case 'containsKey':
        return ({object, positionalArgs, namedArgs}) =>
            object.containsKey(positionalArgs.first);
      case 'containsValue':
        return ({object, positionalArgs, namedArgs}) =>
            object.containsValue(positionalArgs.first);
      case 'addAll':
        return ({object, positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'clear':
        return ({object, positionalArgs, namedArgs}) => object.clear();
      case 'remove':
        return ({object, positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      default:
        return instance[id];
    }
  }

  @override
  dynamic instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    switch (id) {
      default:
        ({object, positionalArgs, namedArgs}) => instance[id] = value;
    }
  }
}

class HTRandomClassBinding extends HTExternalClass {
  HTRandomClassBinding() : super('Random');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Random':
        return ({positionalArgs, namedArgs}) =>
            math.Random(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'nextBool':
        return ({object, positionalArgs, namedArgs}) => object.nextBool();
      case 'nextBoolBiased':
        return ({object, positionalArgs, namedArgs}) {
          final double input = (positionalArgs[0] as num).toDouble();
          final double target = (positionalArgs[1] as num).toDouble();
          return (object as math.Random).nextBoolBiased(input, target);
        };
      case 'nextDouble':
        return ({object, positionalArgs, namedArgs}) => object.nextDouble();
      case 'nearInt':
        return ({object, positionalArgs, namedArgs}) {
          return (object as math.Random)
              .nearInt(positionalArgs.first, exponent: namedArgs['exponent']);
        };
      case 'distantInt':
        return ({object, positionalArgs, namedArgs}) => (object as math.Random)
            .distantInt(positionalArgs.first, exponent: namedArgs['exponent']);
      case 'nextInt':
        return ({object, positionalArgs, namedArgs}) =>
            object.nextInt(positionalArgs[0].toInt());
      case 'nextColorHex':
        return ({object, positionalArgs, namedArgs}) =>
            (object as math.Random).nextColorHex(
              hasAlpha: namedArgs['hasAlpha'],
            );
      case 'nextBrightColorHex':
        return ({object, positionalArgs, namedArgs}) =>
            (object as math.Random).nextBrightColorHex(
              hasAlpha: namedArgs['hasAlpha'],
            );
      case 'nextIterable':
        return ({object, positionalArgs, namedArgs}) =>
            (object as math.Random).nextIterable(positionalArgs.first);
      case 'shuffle':
        return ({object, positionalArgs, namedArgs}) sync* {
          final Iterable iterable = positionalArgs.first;
          if (iterable.isNotEmpty) {
            // ignore: prefer_collection_literals
            final Set indexes = LinkedHashSet();
            int index;
            do {
              do {
                index = object.nextInt(iterable.length);
              } while (indexes.contains(index));
              indexes.add(index);
              yield iterable.elementAt(index);
            } while (indexes.length < iterable.length);
          }
        };
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTFutureClassBinding extends HTExternalClass {
  HTFutureClassBinding() : super('Future');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
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
        return ({object, positionalArgs, namedArgs}) {
          return Future.value(positionalArgs.first);
        };
      case 'Future.delayed':
        return ({object, positionalArgs, namedArgs}) {
          return Future.delayed(
              Duration(milliseconds: (positionalArgs[0] * 1000).truncate()),
              () => positionalArgs[1]?.call());
        };
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    switch (id) {
      case 'then':
        return ({object, positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.then((value) => func.call(positionalArgs: [value]));
        };
      default:
        throw HTError.undefined(id);
    }
  }
}

class HTCryptoClassBinding extends HTExternalClass {
  HTCryptoClassBinding() : super('crypto');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'crypto.randomUUID':
        return ({positionalArgs, namedArgs}) {
          return randomUUID();
        };
      case 'crypto.randomUID':
        return ({positionalArgs, namedArgs}) {
          return randomUID(
            length: namedArgs['length'],
            withTime: namedArgs['withTime'],
          );
        };
      case 'crypto.randomNID':
        return ({positionalArgs, namedArgs}) {
          return randomNID(
            length: namedArgs['length'],
            withTime: namedArgs['withTime'],
          );
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
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class HTConsoleClassBinding extends HTExternalClass {
  Console console;

  HTConsoleClassBinding({required this.console}) : super('console');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
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
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class HTJSONClassBinding extends HTExternalClass {
  HTLexicon lexicon;

  HTJSONClassBinding({required this.lexicon}) : super('JSON');

  @override
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'JSON.parse':
        return ({positionalArgs, namedArgs}) =>
            jsonDecode(positionalArgs.first);
      case 'JSON.jsonify':
        return ({positionalArgs, namedArgs}) => jsonify(positionalArgs.first);
      case 'JSON.stringify':
        return ({positionalArgs, namedArgs}) =>
            lexicon.stringify(positionalArgs.first);
      case 'JSON.deepcopy':
        return ({positionalArgs, namedArgs}) => deepCopy(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}
