import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (
        {List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        HT_Instance instance}) async {
      return {'dartValue': 'hello'};
    },
  });

  await hetu.evalf('script/import_2.ht', invokeFunc: 'main');
}
