import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    class A {
      var name: str
      static fun create(name) {
        return A._(name)
      }
      construct _(name) {
        this.name = name
      }
    }
    fun main {
      // var a = A() // error!
      var a = A.create('Tom')
      print(a.name)
    }

  ''', invoke: 'main');
}
