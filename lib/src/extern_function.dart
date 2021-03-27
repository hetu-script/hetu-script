import 'type.dart';

typedef HTExternalFunction = dynamic Function(
    [List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, List<HTTypeId> typeArgs]);

final Map<String, Function> coreFunctions = {
  // TODO: 读取注释
  'help': (
      [List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const <HTTypeId>[]]) {},
  'print': (
      [List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const <HTTypeId>[]]) {
    var sb = StringBuffer();
    for (final arg in positionalArgs) {
      sb.write('${arg.toString()} ');
    }
    print(sb.toString());
  },
};
