import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun main {
      var j = 3
      var i =
        'hello' 
      +  'hi' 
      +    ' y'

      ++j

        print(i)
        print(j)
    }

  ''', invokeFunc: 'main');
}
