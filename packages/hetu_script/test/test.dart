import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var obj = {
      `name-#42🍎`: 'aleph'
    }

    print(obj.`name-#42🍎`)
    ''', isScript: true);
}
