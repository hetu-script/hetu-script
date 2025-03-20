import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Test {
  static void greeting() {
    print('hello!');
  }
}

class TestClassBinding extends HTExternalClass {
  TestClassBinding() : super('Test');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Test.greeting':
        return ({positionalArgs, namedArgs}) => Test.greeting();
    }
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [TestClassBinding()]);
  final bytes = hetu.compile(r'''
    external class Test {
      static function greeting
    }
    ''');

  hetu.interpreter.loadBytecode(bytes: bytes, module: 'myModule');

  final bytes2 = hetu.compile(r'''
    import 'module:myModule' as m

    function main {
      m.Test.greeting()
    }
    ''');

  hetu.interpreter.loadBytecode(bytes: bytes2, module: 'main', invoke: 'main');
}
