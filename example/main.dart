import 'package:hetu_script/hetu_script.dart';

void main() async {
  // var hetu = await HetuEnv.init();
  // // hetu.evalf('scripts/assign.ht', invokeFunc: 'main');

  // print(hetu.eval('typeof(print)', style: ParseStyle.function));

  var hetu = await HetuEnv.init(externalFunctions: {
    'dartHello': (HT_Instance instance, List<dynamic> args) {
      print('hello from dart');
      if (args.isNotEmpty) for (final arg in args) print(arg);
    },
  });
  hetu.eval(
      'external fun dartHello\n'
      'proc main {\n'
      'dartHello("from hetu")\n'
      '\n}',
      invokeFunc: 'main');
}
