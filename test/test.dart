import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(
    r'''
      var func: function = fun (n: num) { return n + 1 }
      print(func.valueType)
  ''',
    config: InterpreterConfig(codeType: CodeType.script),
    // invokeFunc: 'forwardDecl',
  );
}
