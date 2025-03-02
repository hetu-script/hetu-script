import 'dart:math' as math;
import 'dart:convert';
import 'dart:collection';

import 'package:characters/characters.dart';

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
  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
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
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
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
        return ({positionalArgs, namedArgs}) {
          return positionalArgs.first.toString();
        };
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as String;
    switch (id) {
      case 'characters':
        return Characters(object);
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      case 'compareTo':
        return ({positionalArgs, namedArgs}) =>
            object.compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return ({positionalArgs, namedArgs}) =>
            object.codeUnitAt(positionalArgs[0]);
      case 'length':
        return object.length;
      case 'endsWith':
        return ({positionalArgs, namedArgs}) =>
            object.endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({positionalArgs, namedArgs}) =>
            object.startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({positionalArgs, namedArgs}) =>
            object.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs}) =>
            object.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return object.isEmpty;
      case 'isNotEmpty':
        return object.isNotEmpty;
      case 'substring':
        return ({positionalArgs, namedArgs}) =>
            object.substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({positionalArgs, namedArgs}) => object.trim();
      case 'trimLeft':
        return ({positionalArgs, namedArgs}) => object.trimLeft();
      case 'trimRight':
        return ({positionalArgs, namedArgs}) => object.trimRight();
      case 'padLeft':
        return ({positionalArgs, namedArgs}) =>
            object.padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({positionalArgs, namedArgs}) =>
            object.padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({positionalArgs, namedArgs}) =>
            object.contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({positionalArgs, namedArgs}) => object.replaceFirst(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({positionalArgs, namedArgs}) =>
            object.replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs}) => object.replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({positionalArgs, namedArgs}) => object.split(positionalArgs[0]);
      case 'toLowerCase':
        return ({positionalArgs, namedArgs}) => object.toLowerCase();
      case 'toUpperCase':
        return ({positionalArgs, namedArgs}) => object.toUpperCase();
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
    final object = instance as Iterator;
    switch (id) {
      case 'moveNext':
        return ({positionalArgs, namedArgs}) {
          return object.moveNext();
        };
      case 'current':
        return object.current;
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
    final object = instance as Iterable;
    switch (id) {
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      case 'toJSON':
        return ({positionalArgs, namedArgs}) => jsonifyList(object);
      case 'random':
        final random = math.Random();
        if (object.isNotEmpty) {
          return object.elementAt(random.nextInt(object.length));
        } else {
          return null;
        }
      case 'iterator':
        return object.iterator;
      case 'map':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.map((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'where':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.where((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'expand':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.expand((element) {
            return func.call(positionalArgs: [element]) as Iterable;
          });
        };
      case 'contains':
        return ({positionalArgs, namedArgs}) =>
            object.contains(positionalArgs.first);
      case 'reduce':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.reduce((value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'fold':
        return ({positionalArgs, namedArgs}) {
          final initialValue = positionalArgs[0];
          HTFunction func = positionalArgs[1];
          return object.fold(initialValue, (value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'every':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.every((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'join':
        return ({positionalArgs, namedArgs}) =>
            object.join(positionalArgs.first);
      case 'any':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.any((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'toList':
        return ({positionalArgs, namedArgs}) => object.toList();
      case 'length':
        return object.length;
      case 'isEmpty':
        return object.isEmpty;
      case 'isNotEmpty':
        return object.isNotEmpty;
      case 'take':
        return ({positionalArgs, namedArgs}) =>
            object.take(positionalArgs.first);
      case 'takeWhile':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.takeWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'skip':
        return ({positionalArgs, namedArgs}) =>
            object.skip(positionalArgs.first);
      case 'skipWhile':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return object.skipWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'first':
        return object.isNotEmpty ? object.first : null;
      case 'last':
        return object.isNotEmpty ? object.last : null;
      case 'single':
        return object.single;
      case 'firstWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.firstWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'lastWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.lastWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'singleWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return object.singleWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'elementAt':
        return ({positionalArgs, namedArgs}) =>
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
    final object = instance as List;
    switch (id) {
      case 'addIfAbsent':
        return ({positionalArgs, namedArgs}) {
          if (!object.contains(positionalArgs.first)) {
            object.add(positionalArgs.first);
          }
        };
      case 'add':
        return ({positionalArgs, namedArgs}) =>
            object.add(positionalArgs.first);
      case 'addAll':
        return ({positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'reversed':
        return object.reversed;
      case 'indexOf':
        return ({positionalArgs, namedArgs}) =>
            object.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs}) =>
            object.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return ({positionalArgs, namedArgs}) =>
            object.insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return ({positionalArgs, namedArgs}) =>
            object.insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return ({positionalArgs, namedArgs}) => object.clear();
      case 'remove':
        return ({positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      case 'removeAt':
        return ({positionalArgs, namedArgs}) =>
            object.removeAt(positionalArgs.first);
      case 'removeLast':
        return ({positionalArgs, namedArgs}) => object.removeLast();
      case 'removeFirst':
        return ({positionalArgs, namedArgs}) => object.removeAt(0);
      case 'sublist':
        return ({positionalArgs, namedArgs}) =>
            object.sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return ({positionalArgs, namedArgs}) => object.asMap();
      case 'sort':
        return ({positionalArgs, namedArgs}) {
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
        return ({positionalArgs, namedArgs}) => object.shuffle();
      case 'indexWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int start = positionalArgs[1];
          return object.indexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'lastIndexWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int? start = positionalArgs[1];
          return object.lastIndexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'removeWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'getRange':
        return ({positionalArgs, namedArgs}) =>
            object.getRange(positionalArgs[0], positionalArgs[1]);
      case 'setRange':
        return ({positionalArgs, namedArgs}) => object.setRange(
            positionalArgs[0],
            positionalArgs[1],
            positionalArgs[2],
            positionalArgs[3]);
      case 'removeRange':
        return ({positionalArgs, namedArgs}) =>
            object.removeRange(positionalArgs[0], positionalArgs[1]);
      case 'fillRange':
        return ({positionalArgs, namedArgs}) => object.fillRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs}) => object.replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'clone':
        return ({positionalArgs, namedArgs}) => deepCopy(this);
      default:
        return superClass!.instanceMemberGet(instance, id);
    }
  }

  @override
  void instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    final object = instance as List;
    switch (id) {
      case 'first':
        object.first = value;
      case 'last':
        object.last = value;
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
    final object = instance as Set;
    switch (id) {
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      case 'add':
        return ({positionalArgs, namedArgs}) =>
            object.add(positionalArgs.first);
      case 'addAll':
        return ({positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'remove':
        return ({positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      case 'lookup':
        return ({positionalArgs, namedArgs}) =>
            object.lookup(positionalArgs[0]);
      case 'removeAll':
        return ({positionalArgs, namedArgs}) =>
            object.removeAll(positionalArgs.first);
      case 'retainAll':
        return ({positionalArgs, namedArgs}) =>
            object.retainAll(positionalArgs.first);
      case 'removeWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          object.retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'containsAll':
        return ({positionalArgs, namedArgs}) =>
            object.containsAll(positionalArgs.first);
      case 'intersection':
        return ({positionalArgs, namedArgs}) =>
            object.intersection(positionalArgs.first);
      case 'union':
        return ({positionalArgs, namedArgs}) =>
            object.union(positionalArgs.first);
      case 'difference':
        return ({positionalArgs, namedArgs}) =>
            object.difference(positionalArgs.first);
      case 'clear':
        return ({positionalArgs, namedArgs}) => object.clear();
      case 'toSet':
        return ({positionalArgs, namedArgs}) => object.toSet();
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
    final object = instance as Map;
    switch (id) {
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      case 'length':
        return object.length;
      case 'isEmpty':
        return object.isEmpty;
      case 'isNotEmpty':
        return object.isNotEmpty;
      case 'keys':
        return object.keys;
      case 'values':
        return object.values;
      case 'containsKey':
        return ({positionalArgs, namedArgs}) =>
            object.containsKey(positionalArgs.first);
      case 'containsValue':
        return ({positionalArgs, namedArgs}) =>
            object.containsValue(positionalArgs.first);
      case 'addAll':
        return ({positionalArgs, namedArgs}) =>
            object.addAll(positionalArgs.first);
      case 'clear':
        return ({positionalArgs, namedArgs}) => object.clear();
      case 'remove':
        return ({positionalArgs, namedArgs}) =>
            object.remove(positionalArgs.first);
      default:
        return object[id];
    }
  }

  @override
  dynamic instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    final object = instance as Map;
    switch (id) {
      default:
        object[id] = value;
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
    final object = instance as math.Random;
    switch (id) {
      case 'nextDouble':
        return ({positionalArgs, namedArgs}) => object.nextDouble();
      case 'nearInt':
        return ({positionalArgs, namedArgs}) {
          return (positionalArgs.first *
                  math.pow(object.nextDouble(), namedArgs['exponent'] ?? 0.5))
              .toInt();
        };
      case 'distantInt':
        return ({positionalArgs, namedArgs}) {
          return (positionalArgs.first *
                  (1 -
                      math.pow(
                          object.nextDouble(), namedArgs['exponent'] ?? 0.5)))
              .toInt();
        };
      case 'nextInt':
        return ({positionalArgs, namedArgs}) =>
            object.nextInt(positionalArgs[0].toInt());
      case 'nextBool':
        return ({positionalArgs, namedArgs}) => object.nextBool();
      case 'nextBoolBiased':
        return ({positionalArgs, namedArgs}) {
          final num input = positionalArgs[0];
          final num target = positionalArgs[1];
          if (input >= target) {
            return true;
          } else {
            final difference = (input - target).abs();
            final probability = 1 - (difference / target);
            return object.nextDouble() <= probability;
          }
        };
      case 'nextColorHex':
        return ({positionalArgs, namedArgs}) {
          var prefix = '#';
          if (namedArgs['hasAlpha']) {
            prefix += 'ff';
          }
          return prefix +
              (object.nextDouble() * 16777215)
                  .truncate()
                  .toRadixString(16)
                  .padLeft(6, '0');
        };
      case 'nextBrightColorHex':
        return ({positionalArgs, namedArgs}) {
          var prefix = '#';
          if (namedArgs['hasAlpha']) {
            prefix += 'ff';
          }
          return prefix +
              (object.nextDouble() * 5592405 + 11184810)
                  .truncate()
                  .toRadixString(16)
                  .padLeft(6, '0');
        };
      case 'nextIterable':
        return ({positionalArgs, namedArgs}) {
          final iterable = positionalArgs.first as Iterable;
          if (iterable.isNotEmpty) {
            return iterable.elementAt(object.nextInt(iterable.length));
          } else {
            return null;
          }
        };
      case 'shuffle':
        return ({positionalArgs, namedArgs}) sync* {
          final Iterable list = positionalArgs.first;
          if (list.isNotEmpty) {
            // ignore: prefer_collection_literals
            final Set indexes = LinkedHashSet();
            int index;
            do {
              do {
                index = object.nextInt(list.length);
              } while (indexes.contains(index));
              indexes.add(index);
              yield list.elementAt(index);
            } while (indexes.length < list.length);
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
        return ({positionalArgs, namedArgs}) {
          return Future.value(positionalArgs.first);
        };
      case 'Future.delayed':
        return ({positionalArgs, namedArgs}) {
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
    final object = instance as Future;
    switch (id) {
      case 'then':
        return ({positionalArgs, namedArgs}) {
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
