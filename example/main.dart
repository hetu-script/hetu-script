import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'test');
  hetu.evalf('ht\\private.ht', invokeFunc: 'main');
}
