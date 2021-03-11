import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await HT_Isolate(externalFunctions: {
    'dartHello': (Interpreter interpreter,
        {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Object object}) async {
      return {'dartValue': 'hello'};
    },
  });

  await hetu.evalf('script/import_2.ht', invokeFunc: 'main');
}
