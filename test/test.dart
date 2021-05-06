import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    import 'script/tool/beauty.ht'

    fun importTest {
      print(getBeauty(75, 50, 100))
    }
  ''',
      config: InterpreterConfig(codeType: CodeType.module),
      invokeFunc: 'importTest');
}
