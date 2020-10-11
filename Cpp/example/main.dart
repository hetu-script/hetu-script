import 'package:hetu_script/hetu.dart';

void main() async {
  await hetu.init(workingDir: 'scripts');
  await hetu.evalf('scripts/basic.ht', invokeFunc: 'main');
}
