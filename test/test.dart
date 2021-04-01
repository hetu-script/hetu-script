import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
        class Left {
          var age = 10
          fun m() {
            var b = Right(fun(n) {
              age = n
            })
            b.exec()
          }
        }
        class Right {
          var f
          construct(f) {
            this.f = f
          }
          fun exec () {
            f(5)
          }
        }
        fun main() {
          var a = Left()
          a.m()
          print(a.age)
        }
  ''', codeType: CodeType.module, invokeFunc: 'main');
}
