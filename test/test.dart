import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    struct Tile {
      construct (l, t) {
        this.left = l
        this.top = t
      }
    }

    final obj = {
      name: 'tile',
      ...Tile(2,3)
    }
    print(obj)
  ''');
}
