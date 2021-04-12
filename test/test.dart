import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
        fun main {
          var typename: fun = fun(any) -> num

          var functype: fun(num) -> num = typename

          print(functype.toString())
        }
      ''', invokeFunc: 'main');
}
