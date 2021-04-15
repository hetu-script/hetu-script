import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  final result = await hetu.eval('''
    fun getDartFun(dartfun) {
      print(dartfun)
    }

    fun main {
      
      getDartFun( fun [DartFunTypeDef] { return 42 } )

    }
    ''', invokeFunc: 'main');
  print(result);
}
