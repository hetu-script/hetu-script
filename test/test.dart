import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class PPP {
        fun getNum(j: num) {
          for (var i = 0; i < 3; ++i) {
            if (i == j) {
              return 0
            }
          }
          return -1
        }
      }
      fun main() {
        var p = PPP()
        for (var m = 0; m < 6; ++m) {
          var k = p.getNum(m)
          if (k != -1) {
            print( '${m}: k is 0' )
          } else {
            print( '${m}: k is -1 ' )
          }
        }
        print('where are you?')
      }
  ''',
      config: InterpreterConfig(sourceType: SourceType.module),
      invokeFunc: 'main');
}
