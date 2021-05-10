import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    var i = 42
    fun forwardDecl {
      var j = i
      i = 1
      print(j)
    }
  ''',
      config: InterpreterConfig(codeType: CodeType.module),
      invokeFunc: 'forwardDecl');
}
