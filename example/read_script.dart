import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init(externalFunctions: {
    'dartHello': (HT_Instance instance, List<dynamic> args) async {
      return {'dartValue': 'hello'};
    },
  });

  await hetu.evalf('script/async.ht', invokeFunc: 'main');
}
