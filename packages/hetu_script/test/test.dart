import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var obj = {
      name: {
        foo: {
          bar: 1
        }
      }
    }
    fun structSet {
      obj.name.cur = obj.name.foo
      print(obj)
    }
  ''', invokeFunc: 'structSet');
}
