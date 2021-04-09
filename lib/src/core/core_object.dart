import '../type.dart';
import '../errors.dart';
import '../binding/external_object.dart';
import '../interpreter.dart';
import '../lexicon.dart';

extension IntExtension on int {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'runtimeType':
        return HTType.integer;
      case 'remainder':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            remainder(positionalArgs[0]);
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
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) => toString();
      case 'toRadixString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            toRadixString(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension BoolExtension on bool {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'runtimeType':
        return HTType.boolean;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) => toString();
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension StringExtension on String {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'runtimeType':
        return HTType.string;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) => toString();
      case 'isEmpty':
        return isEmpty;
      case 'subString':
        return substring;
      case 'startsWith':
        return startsWith;
      case 'endsWith':
        return endsWith;
      case 'indexOf':
        return indexOf;
      case 'lastIndexOf':
        return lastIndexOf;
      case 'compareTo':
        return compareTo;
      case 'trim':
        return trim;
      case 'trimLeft':
        return trimLeft;
      case 'trimRight':
        return trimRight;
      case 'padLeft':
        return padLeft;
      case 'padRight':
        return padRight;
      case 'contains':
        return contains;
      case 'replaceFirst':
        return replaceFirst;
      case 'replaceAll':
        return replaceAll;
      case 'replaceRange':
        return replaceRange;
      case 'split':
        return split;
      case 'toLowerCase':
        return toLowerCase;
      case 'toUpperCase':
        return toUpperCase;
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart list.
class HTList extends HTExternalObject {
  @override
  late final rtType;

  HTList(List value, Interpreter interpreter, {HTType valueType = HTType.ANY})
      : super(value, interpreter) {
    rtType = HTType(HTLexicon.list, typeArgs: [valueType]);

    switch (valueType.toString()) {
      case 'str':
        value = List<String>.from(value);
        break;
      case 'int':
        value = List<int>.from(value);
        break;
      case 'float':
        value = List<double>.from(value);
        break;
      case 'bool':
        value = List<bool>.from(value);
        break;
      default:
        value = value;
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return rtType;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.toString();
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'first':
        return externObject.first;
      case 'last':
        return externObject.last;
      case 'contains':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.contains(positionalArgs.first);
      case 'add':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.add(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.clear();
      case 'removeAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.removeAt(positionalArgs.first);
      case 'indexOf':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.indexOf(positionalArgs.first);
      case 'elementAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.elementAt(positionalArgs.first);
      case 'join':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.join(positionalArgs.first);
      default:
        return super.memberGet(varName, from: from);
    }
  }
}

/// Binding object for dart map.
class HTMap extends HTExternalObject {
  @override
  late final rtType;

  HTMap(Map value, Interpreter interpreter,
      {HTType keyType = HTType.ANY, HTType valueType = HTType.ANY})
      : super(value, interpreter) {
    rtType = HTType(HTLexicon.map, typeArgs: [keyType, valueType]);
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return rtType;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.toString();
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'keys':
        return externObject.keys.toList();
      case 'values':
        return externObject.values.toList();
      case 'containsKey':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.containsKey(positionalArgs.first);
      case 'containsValue':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.containsValue(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.clear();
      case 'remove':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externObject.remove(positionalArgs.first);
      default:
        return super.memberGet(varName, from: from);
    }
  }
}
