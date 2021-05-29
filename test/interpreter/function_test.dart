import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('functions -', () {
    test('nested & anonymous', () async {
      final result = await hetu.eval('''
            fun literalFunction(func) {
              var i = 42
              fun nested() {
                i = i + 1
                return (func(i))
              }
              return nested
            }
            fun closure {
              var func = literalFunction( fun (n) { return n * n } )
              func()
              return func()
            }
      ''', invokeFunc: 'closure');
      expect(
        result,
        1936,
      );
    });
    test('closure in loop', () async {
      final result = await hetu.eval('''
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
          return list[1]
        }
      ''', invokeFunc: 'closureInLoop');
      expect(
        result,
        1,
      );
    });
  });
}
