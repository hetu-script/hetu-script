import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r''' 
      fun main() { 
        var rows = [1, 2, 3]

        for (var r in rows) {
          var p = r * r

          print(p)
        } 
 
      }
    ''', invokeFunc: 'main');
}
