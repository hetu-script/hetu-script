import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''

  fun add(n: num) -> num {
    return n + 1
  }

  const a: fun(num) -> num = add

  print(a(3))

      ''', codeType: CodeType.script);
}
