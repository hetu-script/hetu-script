import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun getNum(j: num) {
        for (var i = 0; i < 5; ++i) {
          if (i == j) {
            return i
          }
        }
        return -1
      }
      fun main() {
        var k = getNum(3)
        if (k != -1) {
          print( k )
        } else {
          print( 'k is -1 ' )
        }
        print('where are you?')
      }
      ''', invokeFunc: 'main');
}
