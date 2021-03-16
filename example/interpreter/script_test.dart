import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HTInterpreter();

  hetu.evalf('script/basic.ht', invokeFunc: 'main');
}
