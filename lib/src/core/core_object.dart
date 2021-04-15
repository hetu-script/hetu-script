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
            externalObject.remainder(positionalArgs[0]);
      case 'compareTo':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.compareTo(positionalArgs[0]);
      case 'isNaN':
        return externalObject.isNaN;
      case 'isNegative':
        return externalObject.isNegative;
      case 'isInfinite':
        return externalObject.isInfinite;
      case 'isFinite':
        return externalObject.isFinite;
      case 'clamp':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toStringAsPrecision(positionalArgs[0]);
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
            externalObject.toString();
      case 'modPow':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.modInverse(positionalArgs[0]);
      case 'gcd':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.gcd(positionalArgs[0]);
      case 'isEven':
        return externalObject.isEven;
      case 'isOdd':
        return externalObject.isOdd;
      case 'bitLength':
        return externalObject.bitLength;
      case 'toUnsigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toSigned(positionalArgs[0]);
      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => externalObject.abs();
      case 'sign':
        return externalObject.sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => externalObject.ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.truncateToDouble();
      case 'toRadixString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toRadixString(positionalArgs[0]);
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
            externalObject.toString();
      case 'abs':
        return ({positionalArgs, namedArgs, typeArgs}) => externalObject.abs();
      case 'sign':
        return externalObject.sign;
      case 'round':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.round();
      case 'floor':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.floor();
      case 'ceil':
        return ({positionalArgs, namedArgs, typeArgs}) => externalObject.ceil();
      case 'truncate':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.truncate();
      case 'roundToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.roundToDouble();
      case 'floorToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.floorToDouble();
      case 'ceilToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.ceilToDouble();
      case 'truncateToDouble':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.truncateToDouble();
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
            externalObject.toString();
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
            externalObject.toString();
      case 'codeUnitAt':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.codeUnitAt(positionalArgs[0]);
      case 'length':
        return externalObject.length;
      case 'endsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return externalObject.isEmpty;
      case 'isNotEmpty':
        return externalObject.isNotEmpty;
      case 'subString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({positionalArgs, namedArgs, typeArgs}) => externalObject.trim();
      case 'trimLeft':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.trimLeft();
      case 'trimRight':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.trimRight();
      case 'padLeft':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.replaceFirst(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.split(positionalArgs[0]);
      case 'toLowerCase':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toLowerCase();
      case 'toUpperCase':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toUpperCase();
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
            externalObject.toString();
      case 'length':
        return externalObject.length;
      case 'isEmpty':
        return externalObject.isEmpty;
      case 'isNotEmpty':
        return externalObject.isNotEmpty;
      case 'first':
        return externalObject.first;
      case 'last':
        return externalObject.last;
      case 'contains':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.contains(positionalArgs.first);
      case 'add':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.add(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.clear();
      case 'removeAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.removeAt(positionalArgs.first);
      case 'indexOf':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.indexOf(positionalArgs.first);
      case 'elementAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.elementAt(positionalArgs.first);
      case 'join':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.join(positionalArgs.first);
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
            externalObject.toString();
      case 'length':
        return externalObject.length;
      case 'isEmpty':
        return externalObject.isEmpty;
      case 'isNotEmpty':
        return externalObject.isNotEmpty;
      case 'keys':
        return externalObject.keys.toList();
      case 'values':
        return externalObject.values.toList();
      case 'containsKey':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.containsKey(positionalArgs.first);
      case 'containsValue':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.containsValue(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.clear();
      case 'remove':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            externalObject.remove(positionalArgs.first);
      default:
        return super.memberGet(varName, from: from);
    }
  }
}
