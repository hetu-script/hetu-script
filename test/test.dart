import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun two(x) {return x * 2}
  ''',
      namespace: hetu.coreNamespace,
      config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.eval(r'''
    var j = two(2)
  ''',
      namespace: hetu.coreNamespace,
      config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.eval(r'''
    print(j)
  ''',
      namespace: hetu.coreNamespace,
      config: InterpreterConfig(sourceType: SourceType.script));
}
