import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  hetu.init();

  var r = hetu.eval(r'''
    assert(true, 'message')
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
