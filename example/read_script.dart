import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init();

  await hetu.evalf('script/types.ht', invokeFunc: 'main');
}
