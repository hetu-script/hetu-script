import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  // Minimal reproduction: struct with constructor called via named args
  try {
    hetu.eval(r'''
      struct Tile {
        var left
        var right

        constructor (left, right) {
          this.left = left
          this.right = right
        }
      }

      // Test 1: positional call
      let t1 = Tile(1, 2)
      print(t1)

      // Test 2: named call
      let t2 = Tile(left: 3, right: 4)
      print(t2)
    ''');
  } catch (e) {
    print('ERROR: $e');
  }
}
