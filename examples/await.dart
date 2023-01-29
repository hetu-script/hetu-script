import 'package:hetu_script/hetu_script.dart';

final hetu = Hetu(config: HetuConfig(printPerformanceStatistics: false));
Future<void> main() async {
  hetu.init(
    externalFunctions: {
      'fetch': () =>
          Future.delayed(const Duration(seconds: 3)).then((value) => 3),
    },
  );
  hetu.eval(
    '''
    external fun fetch() -> Future<int>;
    
    fun test1 async {
      print('before');
      await fetch();
      print('after');
      // print(result);
    }

    await test1()
      
    ''',
    // type: HTResourceType.hetuModule,
  );

  // await printResult(hetu.invoke('test1'));
  // await printResult(hetu.invoke('test2'));
  // await printResult(hetu.invoke('test3'));
}

Future<void> printResult(dynamic result) async {
  if (result is Future) {
    result.then((value) => print(hetu.lexicon.stringify(value)));
  } else {
    print(hetu.lexicon.stringify(result));
  }
}
