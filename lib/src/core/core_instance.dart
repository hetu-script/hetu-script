import '../type.dart';
import '../errors.dart';
import '../interpreter.dart';
import '../lexicon.dart';
import '../binding/external_instance.dart';

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
