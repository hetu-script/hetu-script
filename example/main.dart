import 'package:hetu_script/hetu.dart';

void main() {
  var hetu = Hetu();
  hetu.evalf('test\\calculator.hs', invokeFunc: 'main');

  hetu.evalc('System.print hello world 42!');
}
