import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init(
    externalFunctions: {
      'fetch': () =>
          Future.delayed(const Duration(seconds: 3)).then((value) => 3),
    },
  );
  hetu.eval('''
    external function fetch() -> Future<int>;
    
    function test1() async {
      print('before');
      final result = await fetch();
      print('after');
      print(result);
    }
    
    function test2() -> Future<int> async {
      print('before');
      final result = await fetch();
      print('after');
      return result;
    }
    
    function test3() -> Future<String> async {
      print('before');
      return fetch().then((result) {
        print('after');
        return result.toString() + ' - Three';
      });
    }
    ''');

  await printResult(hetu.invoke('test1'));
  await printResult(hetu.invoke('test2'));
  await printResult(hetu.invoke('test3'));
}

Future<void> printResult(dynamic result) async {
  print('________________________\nCHECKING: RESULT');
  print('resultArg: $result');
  if (result is Future) {
    result = await result;
  }
  print(result);
}
