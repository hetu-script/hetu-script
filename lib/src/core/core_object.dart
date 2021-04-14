import '../type.dart';
import '../errors.dart';
import '../interpreter.dart';
import '../lexicon.dart';
import '../binding/external_object.dart';

class HTNumber<T extends num> extends HTExternalObject<T> {
  HTNumber(T value, Interpreter interpreter) : super(value, interpreter);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'remainder':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.remainder(positionalArgs[0]);
      case 'compareTo':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.compareTo(positionalArgs[0]);
      case 'isNaN':
        return externObject.isNaN;
      case 'isNegative':
        return externObject.isNegative;
      case 'isInfinite':
        return externObject.isInfinite;
      case 'isFinite':
        return externObject.isFinite;
      case 'clamp':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toStringAsPrecision(positionalArgs[0]);
    }
  }
}

class HTInteger extends HTNumber<int> {
  HTInteger(int value, Interpreter interpreter) : super(value, interpreter);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return HTType.integer;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toString();
      case 'modPow':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.modInverse(positionalArgs[0]);
      case 'gcd':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.gcd(positionalArgs[0]);
      case 'isEven':
        return externObject.isEven;
      case 'isOdd':
        return externObject.isOdd;
      case 'bitLength':
        return externObject.bitLength;
      case 'toUnsigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toSigned(positionalArgs[0]);
      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.abs();
      case 'sign':
        return externObject.sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.truncateToDouble();
      case 'toRadixString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toRadixString(positionalArgs[0]);
      default:
        return super.memberGet(varName, from: from);
    }
  }
}

class HTFloat extends HTNumber<double> {
  HTFloat(double value, Interpreter interpreter) : super(value, interpreter);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return HTType.float;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toString();
      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.abs();
      case 'sign':
        return externObject.sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.truncateToDouble();
      default:
        return super.memberGet(varName, from: from);
    }
  }
}

class HTBoolean extends HTExternalObject<bool> {
  HTBoolean(bool value, Interpreter interpreter) : super(value, interpreter);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return HTType.boolean;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toString();
      default:
        throw HTError.undefined(varName);
    }
  }
}

class HTString extends HTExternalObject<String> {
  HTString(String value, Interpreter interpreter) : super(value, interpreter);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return HTType.string;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toString();
      case 'codeUnitAt':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.codeUnitAt(positionalArgs[0]);
      case 'length':
        return externObject.length;
      case 'endsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'subString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({positionalArgs, namedArgs, typeArgs}) => externObject.trim();
      case 'trimLeft':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.trimLeft();
      case 'trimRight':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.trimRight();
      case 'padLeft':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.replaceFirst(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.split(positionalArgs[0]);
      case 'toLowerCase':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toLowerCase();
      case 'toUpperCase':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externObject.toUpperCase();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart list.
class HTList<T> extends HTExternalObject<List<T>> {
  @override
  late final rtType;

  HTList(List<T> value, Interpreter interpreter,
      {HTType valueType = HTType.ANY})
      : super(value, interpreter) {
    rtType = HTType(HTLexicon.list, typeArgs: [valueType]);
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
