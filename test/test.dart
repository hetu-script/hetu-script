import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class Name {
        var first = 'tom'
      }
      class Member {
        var array = {'tom': 'kaine'}
        var name = Name()
      }
      fun getGlobalVar() {
        var m = Member()
        print(m.array[m.name.first])
      }
      ''', invokeFunc: 'getGlobalVar');
}
