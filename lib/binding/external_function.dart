import '../type_system/type.dart';
import '../core/function/abstract_function.dart' show AbstractFunction;

/// typedef of external function for binding.
typedef HTExternalFunction = dynamic Function(
    {List<dynamic> positionalArgs,
    Map<String, dynamic> namedArgs,
    List<HTType> typeArgs});

/// Accept a hetu function object, then return a dart function
/// for use in Dart code. This is for usage where you want to
/// write a function in script. and want to pass it to a
/// external dart function where it accepts only a pure Dart
/// native function as parameter.
typedef HTExternalFunctionTypedef = Function Function(
    AbstractFunction hetuFunction);

class DaobjectTypeReflectResult {
  final bool success;
  final String typeString;

  DaobjectTypeReflectResult(this.success, this.typeString);
}

typedef HTExternalTypeReflection = DaobjectTypeReflectResult Function(
    dynamic object);
