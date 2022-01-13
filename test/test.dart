import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final obj = {
      name: 'jimmy'
    }

    final greeting = () {
      print('Hi! I\'m ${this.name}')
    }

    greeting.apply(obj)
  ''');
}
