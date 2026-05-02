import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  hetu.init();

  var r = hetu.eval(r'''
    struct Tile {
      var left
      var right

      constructor (left, right) {
        this.left = left
        this.right = right
      }
    }

    struct Test {
      constructor (left, right) {
        Object.assign(this, Tile(left, right))
      }
    }

    let obj = Test(1, 2)
    obj
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
