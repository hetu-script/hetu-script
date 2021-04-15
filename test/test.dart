import 'package:hetu_script/hetu_script.dart';

String getStr() {
  return 'a \n b';
}

void main() async {
  final hetu = Hetu();
  await hetu.init(externalFunctions: {'getStr': () => getStr()});
  await hetu.eval(r'''
        class AGuy {
          var name
          construct withName (name: str) {
            this.name = name
          }
        }
        fun namedConstructor {
          var p = AGuy.withName('harry')
          print(p.name)
        }
    ''', invokeFunc: 'namedConstructor');
}
