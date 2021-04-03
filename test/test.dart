import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval('''
      fun main {
        var j = 0
        for (var i = 0; i < 5; ++i) {
          if (i % 2 == 0){
            continue
          }
          j += i
        }
        print(j)
      }
      ''', invokeFunc: 'main');
}
