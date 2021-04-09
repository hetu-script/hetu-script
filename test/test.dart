import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  final result = await hetu.eval(r'''
        fun main {
          var i: List<String> = ["dd", "2", "3"]
          i[1] = 'as'
          return i
        }
      ''', invokeFunc: 'main');
  print(result);
}
