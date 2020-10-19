import 'package:hetu_script/hetu.dart';

void main() async {
  var interpreter = await HetuEnv.init();
  await interpreter.evalf('scripts/basic.ht', invokeFunc: 'main');
}
