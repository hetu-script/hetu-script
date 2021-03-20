import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();

  await hetu.init();

  await hetu.import('types.ht', invokeFunc: 'main');
}
