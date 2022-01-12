import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      struct Tile {
        construct (left, top) {
          this.left = left
          this.top = top
          // 切换为 horizontal hexgonal tile map 的坐标系
          // 以 (1, 1) 为原点，该格子相对向右下行的斜线的距离
          this.slashLeft = ((left.isOdd ? (left + 1) / 2 : left / 2) - top).truncate()
          // 以 (1, 1) 为原点，该格子相对向右上行的斜线的距离
          this.slashTop = left - this.slashLeft - 1
        }

        construct fromPosition(position) : this(position.left, position.top)
      }

      final t1 = Tile(5, 5)
      final t2 = Tile.fromPosition({left: 5, top: 5})

      print(t1, t2)
    ''');

  print(result);
}
