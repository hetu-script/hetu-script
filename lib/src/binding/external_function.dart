import '../type.dart' show HTType;
import '../function.dart' show HTFunction;

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
typedef HTExternalFunctionTypedef = Function Function(HTFunction hetuFunction);
