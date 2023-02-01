import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

late final Hetu hetu;
final sourceContext = HTFileSystemResourceContext(root: 'test/async/');

Future<void> main() async {
  hetu = Hetu(
    config: HetuConfig(printPerformanceStatistics: false),
    sourceContext: sourceContext,
  );
  hetu.init(
    externalFunctions: {
      'fetch': () =>
          Future.delayed(const Duration(seconds: 1)).then((value) => 3),
      'fetchFailed': () => Future.delayed(const Duration(seconds: 1))
          .then((value) => throw Exception('some error')),
    },
  );
  hetu.evalFile('test_async.ht');

  await check(name: 'test1');
  await check(name: 'test2');
  await check(name: 'test3');
  // await check(name: 'test4'); // manually throw error
  await check(name: 'test5');
  await check(name: 'test6');
  await check(name: 'test7');
  await check(name: 'test8');
  await check(name: 'test9', posArgs: [true]);
  await check(name: 'test9', posArgs: [false]);
  await check(name: 'test10');
  await check(name: 'test11');
  await check(name: 'test12');
  await check(name: 'test13');
  await check(name: 'test14');

  print('ALL TEST FINISHED!');
}

Future<void> check({required String name, List posArgs = const []}) async {
  dynamic result = hetu.invoke(name, positionalArgs: posArgs);
  print('________________________\nTESTING: $name');
  if (result is Future) {
    result = await result;
  }
  print('resultValue: $result');
}
