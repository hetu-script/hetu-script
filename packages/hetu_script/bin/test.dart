import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      var ht = {
        name: 'Jimmy',
      }
      var j = ['243', '2342']
      print(stringify(ht))
  ''', asScript: true);
}
