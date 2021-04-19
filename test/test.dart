import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
        fun closureInLoop {
          var list = [];
          var builders = [];
          fun build(i, add) {
            builders.add(fun () {
              add(i);
            });
          }
          for (var i = 0; i < 5; ++i) {
            build(i, fun (n)  {
              list.add(n);
            });
          }
          for (var func in builders) {
            func();
          }
          print(list[1])
        }
    ''', invokeFunc: 'closureInLoop');
}
