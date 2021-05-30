import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(
    r'''
    class Base {
      var name = 'Base'
    }

    class D1 extends Base {
      construct (tag) {
        name = '${tag} ${name}'
      }
      
    }

    var d1 = D1('d1')
    print(d1.name)
    var d2 = D1('d2')
    print(d2.name)
    print(d1.name)
  ''',
    config: InterpreterConfig(sourceType: SourceType.script),
    // invokeFunc: 'forwardDecl',
  );
}
