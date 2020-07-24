import 'package:hetu_script/hetu.dart';

void main() {
  hetu.init(workingDir: 'test');
  hetu.evalf('test\\main.ht', invokeFunc: 'main');

  //hetu.evalc('System.print hello world 42!');
}
