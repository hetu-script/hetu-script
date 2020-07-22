import 'package:hetu_script/hetu.dart';

void main() {
  Hetu.init();
  Hetu.evalf('test\\calculator.hs', invokeFunc: 'main');

  Hetu.eval('println hello world 42!', style: ParseStyle.commandLine);
}
