import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init();
  await hetu.evalf('script/string.ht', invokeFunc: 'main');
}
