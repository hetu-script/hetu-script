import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(
    r'''
      var a: function(num) -> num = fun(n: any) -> any { return any }
      print(a.valueType)
  ''',
    config: InterpreterConfig(codeType: CodeType.script),
    // invokeFunc: 'forwardDecl',
  );
}
