import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    class A {
      var name: string
      static function create(name) {
        return A._(name)
      }
      constructor _(name) {
        this.name = name
      }
    }
    function main {
      // var a = A() // error!
      var a = A.create('Tom')
      print(a.name)
    }

  ''', invoke: 'main');
}
