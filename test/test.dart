import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
        fun swtich(expr) {
          when(expr) {
            0-> return '0'
            1-> return '1'
            else-> return 'else'
          }
          return 'missed'
        }
        print( swtich(5 - 2) )
    ''', codeType: CodeType.script);
}
