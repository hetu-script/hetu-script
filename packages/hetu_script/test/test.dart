import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final obj = {
      name: 'nobody'
    }
    final func = () {
      this.name = 'foobar'
    }
    final newfunc =func.bind(obj)
    newfunc()
    print(obj.name)
    ''', isScript: true);
}
