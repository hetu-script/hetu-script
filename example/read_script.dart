import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init();
  var functions_result = await hetu.evalf('script/class.ht', invokeFunc: 'main');
  print(functions_result);
}
