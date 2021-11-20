import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  final result = hetu.evalFile('script/import_test2.ht', invokeFunc: 'main');
  print(result);
}
