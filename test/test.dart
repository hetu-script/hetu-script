import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  void greeting({String? name}) {
    print('hi, $name!');
  }
}

class PersonBinding extends HTExternalClass {
  PersonBinding() : super('Person');

  dynamic memberGet(String id, {String? from, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person':
        return ({positionalArgs, namedArgs}) => Person();
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Person;
    switch (id) {
      case 'greeting':
        return ({positionalArgs, namedArgs}) {
          final name = namedArgs['name'];
          return object.greeting(name: name);
        };
    }
  }
}

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(
      normalizeImportPath: false,
      allowImplicitNullToZeroConversion: true,
      printPerformanceStatistics: true,
    ),
  );
  hetu.init(externalClasses: [PersonBinding()]);

  sourceContext.addResource('source1.ht', HTSource('''
  
  '''));

  hetu.interpreter.bindExternalFunction('Somespace::externalFunc', (
      {positionalArgs, namedArgs}) {
    return 'external function called';
  });

  var r = hetu.eval(r'''
    namespace Somespace {
      external function externalFunc
    }
    Somespace.externalFunc()
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
