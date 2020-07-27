import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'ht');
  hetu.evalf('ht\\list.ht', invokeFunc: 'main');
}
