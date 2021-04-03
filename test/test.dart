import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [GlobalStateClassBinding()]);
  await hetu.eval('''
      fun main {
        for (var i = 0; i < 5; ++i) {
          print(i)
          if (i % 2 == 0){
            continue;
          }
          print('lalal')
        }
      }
      ''', invokeFunc: 'main');
}
