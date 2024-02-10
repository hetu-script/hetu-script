import 'package:hetu_script/hetu_script.dart';

var i = 0;

class Test {
  // instances of Test will get a incremental index
  var n = i++;

  void method() {
    // print out this instance's index
    print(n);
  }
}

void main() {
  final hetu =
      Hetu(config: HetuConfig(resolveExternalFunctionsDynamically: true));
  hetu.init();
  hetu.eval('external function test');

  void run() {
    final t = Test();
    t.method();
  }

  run();
  run();

  void run2() {
    final t = Test();
    hetu.interpreter.bindExternalFunction('test', () {
      t.method();
    });
    hetu.invoke('test');
  }

  run2();
  run2();

  final t = Test();
  t.method();
}
