import 'dart:math' as math;
import 'dart:collection';

import 'package:characters/characters.dart';

import '../value/entity.dart';
import '../type/type.dart';
import '../locale/locale.dart';
import '../error/error.dart';
import '../utils/jsonify.dart';
import '../value/function/function.dart';
import '../utils/collection.dart';

extension NumBinding on num {
  dynamic htFetch(String id) {
    switch (id) {
      case 'toPercentageString':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final fractionDigits = positionalArgs.first;
          return (this * 100).toStringAsFixed(fractionDigits).toString() +
              HTLocale.current.percentageMark;
        };
      case 'compareTo':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'remainder':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remainder(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'abs':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            abs();
      case 'sign':
        return sign;
      case 'round':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            round();
      case 'floor':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floor();
      case 'ceil':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceil();
      case 'truncate':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncate();
      case 'roundToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            roundToDouble();
      case 'floorToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floorToDouble();
      case 'ceilToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceilToDouble();
      case 'truncateToDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncateToDouble();
      case 'toInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toInt();
      case 'toDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toDouble();
      case 'toStringAsFixed':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsPrecision(positionalArgs[0]);
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

extension IntBinding on int {
  dynamic htFetch(String id) {
    switch (id) {
      case 'modPow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modInverse(positionalArgs[0]);
      case 'gcd':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gcd(positionalArgs[0]);
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'bitLength':
        return bitLength;
      case 'toUnsigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSigned(positionalArgs[0]);
      case 'toRadixString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toRadixString(positionalArgs[0]);
      default:
        // ignore: unnecessary_cast
        return (this as num).htFetch(id);
    }
  }
}

extension BigIntBinding on BigInt {
  dynamic htFetch(String id) {
    switch (id) {
      case 'bitLength':
        return bitLength;
      case 'sign':
        return sign;
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'isNegative':
        return isNegative;
      case 'pow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            pow(positionalArgs.first);
      case 'modPow':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modInverse(positionalArgs.first);
      case 'gcd':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gcd(positionalArgs.first);
      case 'toUnsigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUnsigned(positionalArgs.first);
      case 'toSigned':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSigned(positionalArgs.first);
      case 'isValidInt':
        return isValidInt;
      case 'toInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toInt();
      case 'toDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toDouble();
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'toRadixString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toRadixString(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

extension DoubleBinding on double {
  dynamic htFetch(String id) {
    switch (id) {
      case 'toDoubleAsFixed':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            double.parse(toStringAsFixed(positionalArgs.first));
      default:
        // ignore: unnecessary_cast
        return (this as num).htFetch(id);
    }
  }
}

extension StringBinding on String {
  dynamic htFetch(String id) {
    switch (id) {
      case 'characters':
        return Characters(this);
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'compareTo':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            codeUnitAt(positionalArgs[0]);
      case 'length':
        return length;
      case 'endsWith':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            endsWith(positionalArgs[0]);
      case 'startsWith':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'substring':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trim();
      case 'trimLeft':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimLeft();
      case 'trimRight':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimRight();
      case 'padLeft':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceFirst(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            split(positionalArgs[0]);
      case 'toLowerCase':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toLowerCase();
      case 'toUpperCase':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUpperCase();
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart [Iterator]
extension IteratorBinding on Iterator {
  dynamic htFetch(String id) {
    switch (id) {
      case 'moveNext':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return moveNext();
        };
      case 'current':
        return current;
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart [Iterable].
extension IterableBinding on Iterable {
  dynamic htFetch(String id) {
    switch (id) {
      case 'toJson':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            jsonifyList(this);
      case 'iterator':
        return iterator;
      case 'map':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return map((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'where':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return where((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'expand':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return expand((element) {
            return func.call(positionalArgs: [element]) as Iterable;
          });
        };
      case 'contains':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs.first);
      case 'reduce':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return reduce((value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'fold':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final initialValue = positionalArgs[0];
          HTFunction func = positionalArgs[1];
          return fold(initialValue, (value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'every':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return every((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'join':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            join(positionalArgs.first);
      case 'any':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return any((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'toList':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toList();
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'take':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            take(positionalArgs.first);
      case 'takeWhile':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return takeWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'skip':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            skip(positionalArgs.first);
      case 'skipWhile':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return skipWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'first':
        return first;
      case 'last':
        return last;
      case 'single':
        return single;
      case 'firstWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return firstWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'lastWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return lastWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'singleWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return singleWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'elementAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            elementAt(positionalArgs.first);
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart list.
extension ListBinding on List {
  dynamic htFetch(String id) {
    switch (id) {
      case 'add':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            add(positionalArgs.first);
      case 'addAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'reversed':
        return reversed;
      case 'indexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      case 'removeAt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeAt(positionalArgs.first);
      case 'removeLast':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeLast();
      case 'sublist':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            asMap();
      case 'sort':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction? func = positionalArgs.first;
          int Function(dynamic, dynamic)? sortFunc;
          if (func != null) {
            sortFunc = (a, b) {
              return func.call(positionalArgs: [a, b]) as int;
            };
          }
          sort(sortFunc);
        };
      case 'shuffle':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            shuffle();
      case 'indexWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          int start = positionalArgs[1];
          return indexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'lastIndexWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          int? start = positionalArgs[1];
          return lastIndexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'removeWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'getRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            getRange(positionalArgs[0], positionalArgs[1]);
      case 'setRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            setRange(positionalArgs[0], positionalArgs[1], positionalArgs[2],
                positionalArgs[3]);
      case 'removeRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeRange(positionalArgs[0], positionalArgs[1]);
      case 'fillRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            fillRange(positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceRange':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'clone':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            deepCopy(this);
      default:
        // ignore: unnecessary_cast
        return (this as Iterable).htFetch(id);
    }
  }

  dynamic htAssign(String id, dynamic value) {
    switch (id) {
      case 'first':
        first = value;
      case 'last':
        last = value;
      default:
        throw HTError.undefined(id);
    }
  }
}

extension SetBinding on Set {
  dynamic htFetch(String id) {
    switch (id) {
      case 'add':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            add(positionalArgs.first);
      case 'addAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'remove':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      case 'lookup':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lookup(positionalArgs[0]);
      case 'removeAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeAll(positionalArgs.first);
      case 'retainAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            retainAll(positionalArgs.first);
      case 'removeWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'containsAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsAll(positionalArgs.first);
      case 'intersection':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            intersection(positionalArgs.first);
      case 'union':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            union(positionalArgs.first);
      case 'difference':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            difference(positionalArgs.first);
      case 'clear':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'toSet':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSet();
      default:
        // ignore: unnecessary_cast
        return (this as Iterable).htFetch(id);
    }
  }
}

/// Binding object for dart map.
extension MapBinding on Map {
  dynamic htFetch(String id) {
    switch (id) {
      case 'toString':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'keys':
        return keys;
      case 'values':
        return values;
      case 'containsKey':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsKey(positionalArgs.first);
      case 'containsValue':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsValue(positionalArgs.first);
      case 'addAll':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'clear':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      default:
        throw HTError.undefined(id);
    }
  }
}

extension RandomBinding on math.Random {
  dynamic htFetch(String id) {
    switch (id) {
      case 'nextDouble':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            nextDouble();
      case 'nextInt':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            nextInt(positionalArgs[0].toInt());
      case 'nextBool':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            nextBool();
      case 'nextColorHex':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          var prefix = '#';
          if (namedArgs['hasAlpha']) {
            prefix += 'ff';
          }
          return prefix +
              (nextDouble() * 16777215)
                  .truncate()
                  .toRadixString(16)
                  .padLeft(6, '0');
        };
      case 'nextBrightColorHex':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          var prefix = '#';
          if (namedArgs['hasAlpha']) {
            prefix += 'ff';
          }
          return prefix +
              (nextDouble() * 5592405 + 11184810)
                  .truncate()
                  .toRadixString(16)
                  .padLeft(6, '0');
        };
      case 'nextIterable':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          final iterable = positionalArgs.first as Iterable;
          if (iterable.isNotEmpty) {
            return iterable.elementAt(nextInt(iterable.length));
          } else {
            return null;
          }
        };
      case 'shuffle':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) sync* {
          final Iterable list = positionalArgs.first;
          if (list.isNotEmpty) {
            // ignore: prefer_collection_literals
            final Set indexes = LinkedHashSet();
            int index;
            do {
              do {
                index = nextInt(list.length);
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

/// Binding object for dart [Future].
extension FutureBinding on Future {
  dynamic htFetch(String id) {
    switch (id) {
      case 'then':
        return (HTEntity entity,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs.first;
          return then((value) => func.call(positionalArgs: [value]));
        };
      default:
        throw HTError.undefined(id);
    }
  }
}
