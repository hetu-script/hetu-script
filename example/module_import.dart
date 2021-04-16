import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  final result =
      await hetu.import('script/import_test.ht', invokeFunc: 'importTest');
  print(result);
}
