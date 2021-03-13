import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_Interpreter(externalFunctions: {
    'dartHello': (HT_Interpreter interpreter,
        {List<dynamic>? positionalArgs = const [],
        Map<String, dynamic>? namedArgs = const {},
        HT_Object? object}) async {
      return {'dartValue': 'hello'};
    },
  });

  hetu.evalf('script/import_2.ht', invokeFunc: 'main');
}
