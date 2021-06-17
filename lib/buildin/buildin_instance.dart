import '../declaration/type/type.dart';
import '../error/error.dart';

extension IntBinding on int {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'modPow':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            modInverse(positionalArgs[0]);
      case 'gcd':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            gcd(positionalArgs[0]);
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'bitLength':
        return bitLength;
      case 'toUnsigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toSigned(positionalArgs[0]);
      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => abs();
      case 'sign':
        return sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) => round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) => floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) => truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => truncateToDouble();
      case 'toRadixString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toRadixString(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension DoubleBinding on double {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => abs();
      case 'sign':
        return sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) => round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) => floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) => truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) => truncateToDouble();
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension StringBinding on String {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'compareTo':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            codeUnitAt(positionalArgs[0]);
      case 'length':
        return length;
      case 'endsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'subString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({positionalArgs, namedArgs, typeArgs}) => trim();
      case 'trimLeft':
        return ({positionalArgs, namedArgs, typeArgs}) => trimLeft();
      case 'trimRight':
        return ({positionalArgs, namedArgs, typeArgs}) => trimRight();
      case 'padLeft':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({positionalArgs, namedArgs, typeArgs}) => replaceFirst(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs, typeArgs}) => replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            split(positionalArgs[0]);
      case 'toLowerCase':
        return ({positionalArgs, namedArgs, typeArgs}) => toLowerCase();
      case 'toUpperCase':
        return ({positionalArgs, namedArgs, typeArgs}) => toUpperCase();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart list.
extension ListBinding on List {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'contains':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs.first);
      case 'elementAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            elementAt(positionalArgs.first);
      case 'join':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            join(positionalArgs.first);
      case 'first':
        return first;
      case 'last':
        return last;
      case 'length':
        return length;
      case 'add':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            add(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'reversed':
        return reversed;
      case 'indexOf':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      case 'removeAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeAt(positionalArgs.first);
      case 'removeLast':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeLast();
      case 'sublist':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            asMap();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart map.
extension MapBinding on Map {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'keys':
        return keys.toList();
      case 'values':
        return values.toList();
      case 'containsKey':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsKey(positionalArgs.first);
      case 'containsValue':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsValue(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}
