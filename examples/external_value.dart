import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final a = 6;
  final r = hetu.eval(
      '''
  fun test(a) {
    return a * 7
  }
''',
      type: HTResourceType.hetuModule,
      invokeFunc: 'test',
      positionalArgs: [a]);

  print(r);
}
