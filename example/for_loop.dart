import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r''' 
      fun main() { 
        var rows = [1, 2, 3]

        for (var attr in rows) {
          var p = attr * attr

          print(p)
        } 
 
      }
    ''', invokeFunc: 'main');
}
