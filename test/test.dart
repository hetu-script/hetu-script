import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun getID(expr) {
      when {
        (1 > 3) -> return '0'
        (1 > 5) -> return '1'
        else -> return 'else'
      }
      return 'missed'
    }

    print(getID(5 - 2))

  
    ''', codeType: CodeType.script);
}
