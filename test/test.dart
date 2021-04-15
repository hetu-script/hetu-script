import 'package:hetu_script/hetu_script.dart';

String getStr() {
  return 'a \n b';
}

void main() async {
  final hetu = Hetu();
  await hetu.init(externalFunctions: {'getStr': () => getStr()});
  await hetu.eval(r'''
    external fun getStr
    fun main {
      var a = getStr()
      print(a)
    }
    ''', invokeFunc: 'main');
}
