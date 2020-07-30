import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_example');
  hetu.evalf('ht_example\\evaluation.ht', invokeFunc: 'main');
}
