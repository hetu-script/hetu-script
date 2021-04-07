import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''

  fun main {
    var a: fun(any) -> any = fun(n: num) -> num { return n + 1 }

    print(a.rtType)
  }

      ''', invokeFunc: 'main');
}
