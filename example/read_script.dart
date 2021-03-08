import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, Map<String, dynamic> args) async {
      return {'dartValue': 'hello'};
    },
  });

  await hetu.evalf('script/import_2.ht', invokeFunc: 'main');
}
