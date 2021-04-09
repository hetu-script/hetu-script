import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun whenSwitch() {
        var i = 4
          when (i % 2) {
            0: {print('even')}
            1: {print('odd')}
          }
      }
      ''', invokeFunc: 'whenSwitch');
}
