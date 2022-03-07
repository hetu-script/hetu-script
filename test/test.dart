import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu()..strictMode = true;
  hetu.init();
  hetu.eval(r'''
    var p = 'PPP'
    var m = 'MMM'
    final s = '
${
      p
      +
      m
    }'
    print(s)
    print('a
multiline
string
')
  ''');
}
