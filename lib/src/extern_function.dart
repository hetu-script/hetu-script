import 'type.dart';

import 'function.dart';

typedef HTExternalFunction = dynamic Function(
    {List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, List<HTTypeId> typeArgs});

/// Accept a hetu function object, then return a dart function
/// for use in Dart code. This is for usage where you want to
/// write a function in script. and want to pass it to a
/// external dart function where it accepts only a pure Dart
/// native function as parameter.
typedef HTExternalFunctionTypedef = Function Function(HTFunction hetuFunction);

final Map<String, Function> coreFunctions = {
  // TODO: 读取注释
  'help': (
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {},
  'print': (
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    var sb = StringBuffer();
    for (final arg in positionalArgs[0]) {
      sb.write('$arg ');
    }
    print(sb.toString());
  },
};
