import 'package:hetu_script/hetu_script.dart';

Future<void> fetch() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(
      const Duration(seconds: 2), () => 'Hello world after 2 seconds!');
}

void main() {
  final hetu = Hetu();
  hetu.init(externalFunctions: {'fetch': fetch});
  hetu.eval(r'''
      external function fetch
      print('begin future here')
      final value = await fetch()
      print('future completed! value="${value}"')
  ''');
}
