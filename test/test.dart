import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    var i = 42
    fun forwardDecl() {
      i = 41
      print('i: ${i}')
      var j = i
      print('j: ${j}')

    }
  ''',
      config: InterpreterConfig(codeType: CodeType.module),
      invokeFunc: 'forwardDecl');
}
