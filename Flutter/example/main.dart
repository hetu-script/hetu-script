import 'package:hetu_script_flutter/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht_example');
  hetu.evalf('script\\basic.ht', invokeFunc: 'main');
}
