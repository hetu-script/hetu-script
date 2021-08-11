import '../type/type.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> buildinFunctions = {
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
    print(sb.toString().trimRight());
  },
  'stringify': (
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return positionalArgs.first.toString();
  },
};
