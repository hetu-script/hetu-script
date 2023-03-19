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
  dynamic memberGet(String id, {String? from}) {
    switch (id) {
      case 'Test.greeting':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Test.greeting();
    }
  }
}

void main() {
  final hetu = Hetu();
  hetu.init(externalClasses: [TestClassBinding()]);
  final bytes = hetu.compile(r'''
    external class Test {
      static fun greeting
    }

    fun main {
      Test.greeting()
    }
    ''');

  hetu.interpreter.loadBytecode(bytes: bytes, module: 'myModule');

  hetu.eval(r'''
  import 'module:myModule' as m

  m.main()
''');
}
