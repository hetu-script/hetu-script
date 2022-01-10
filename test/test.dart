import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final result = hetu.eval(r'''
    type AType = {
      name: str,
      greeting: () -> any,
    }
    var a: {} = {
      name: 'jimmy',
      greeting: () {
        print('hi! I\'m ${this.name}')
      }
    }
    print(a is AType)
    ''');

  print(result);
}
