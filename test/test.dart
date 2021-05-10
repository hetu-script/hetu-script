import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    var i = 42
    fun main() {
      var j = i
      i = 1
      print(j)
      var j = i + '34'
    }
  ''',
      config: InterpreterConfig(codeType: CodeType.module), invokeFunc: 'main');
}
