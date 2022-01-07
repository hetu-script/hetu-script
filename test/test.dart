import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
    var a: {} = {
      name: 'jimmy',
      greeting: () {
        print('hi! I\'m ${this.name}')
      }
    }
    print(typeof a)
    ''');

  print(result);
}
