import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun main {
      
      var a = 'a \n b'

      print(a.toString())
    }
    ''', invokeFunc: 'main');
}
