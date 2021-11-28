import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  hetu.eval(r'''
    fun test {
      var name1 = 'jimmy'
      name1 += 'tom'
      print(name1)
    }
  ''', invokeFunc: 'test');
}
