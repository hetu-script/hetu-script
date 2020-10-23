import 'package:hetu_script/hetu.dart';

void main() async {
  var hetu = await HetuEnv.init();
  await hetu.evalf('scripts/basic.ht', invokeFunc: 'main');
}
