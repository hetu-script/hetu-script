typedef HTExternalFunction = dynamic Function(List<dynamic> positionalArgs, Map<String, dynamic> namedArgs);

abstract class HTExternalFunctions {
  static final Map<String, Function> functions = {
    // TODO: 读取注释
    'help': (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) {},
    'print': (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) {
      var sb = StringBuffer();
      for (final arg in positionalArgs) {
        sb.write('${arg.toString()} ');
      }
      print(sb.toString());
    },
  };
}
