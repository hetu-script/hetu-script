import '../type.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> coreFunctions = {
  // TODO: 读取注释
  'help': (
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {},
  'print': (
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    var sb = StringBuffer();
    for (final arg in positionalArgs.first) {
      sb.write('$arg ');
    }
    print(sb.toString());
  },
};
