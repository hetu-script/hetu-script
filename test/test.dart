import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  hetu.init();

  // var r =
  hetu.eval(r'''
    fun test1 ({arg1 = true}) {

    }

    fun arg1 ( ) {
      print('arg1 called!');
    }
  ''');

  hetu.invoke('test1');
  hetu.invoke('arg1');

  // if (r is Future) {
  //   print('wait for async function...');
  //   r = await r;
  // }

  // print(hetu.stringify(r));
}
