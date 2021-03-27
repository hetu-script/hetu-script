import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();

  await hetu.init();

  await hetu.import('script/import_2.ht', invokeFunc: 'main');
}
