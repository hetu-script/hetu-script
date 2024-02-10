import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  var a = 0;
  void setA(int v) {
    a = v;
  }

  int getA() {
    return a;
  }

  hetu.init(
    externalFunctions: {
      'setA': setA,
      'getA': getA,
    },
  );
  hetu.eval(
      '''
  external function getA
  external function setA(v)
  function test() {
    setA(42)
    final a = getA()
    print(a)
  }
''',
      type: HTResourceType.hetuModule,
      invoke: 'test',
      positionalArgs: [a]);
}
