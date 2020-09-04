import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_example');
  hetu.evalf('example\\script\\generic_type.ht', invokeFunc: 'main');
}
