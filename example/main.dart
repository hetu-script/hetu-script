import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_example');
  hetu.evalf('ht_example\\simcity2.ht', invokeFunc: 'main');
}
