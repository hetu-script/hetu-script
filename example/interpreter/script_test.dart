import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTInterpreter();

  await hetu.import('script/basic.ht', invokeFunc: 'main');
}
