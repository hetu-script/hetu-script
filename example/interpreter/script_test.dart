import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTInterpreter();

  await hetu.init();

  await hetu.import('script/types.ht', invokeFunc: 'main');
}