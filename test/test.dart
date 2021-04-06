import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class Super {
        var name
        construct (name) {
          this.name = name
        }
      }
      class Derived extends Super {
        construct: super('derived') {
          name += ' sequence'
        }
      }
      fun cotrSequence {
        var d = Derived()

        print(d.name)
      }
      ''', invokeFunc: 'cotrSequence');
}
