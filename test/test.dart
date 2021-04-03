import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      var globalVar = 0
      class GetGlobal {
        construct {
          globalVar = 2
        }
        fun test {
          return (globalVar * globalVar)
        }
        static fun staticTest {
          return (globalVar + 1)
        }
s      }
      fun getGlobalVar() {
        var a = GetGlobal()
        print( a.test() + GetGlobal.staticTest())
      }
      ''', invokeFunc: 'getGlobalVar');
}
