import 'package:hetu_script/hetu_script.dart';

Future<void> fetch() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(
      const Duration(seconds: 2), () => 'Hello world after 2 seconds!');
}

void main() {
  var hetu = Hetu();
  hetu.init(externalFunctions: {'fetch': fetch});
  hetu.eval(r'''
      external fun fetch
      final future = fetch().then((value) {
          print('future completed! value=${value}')
          return '${value} From the Future!';
        })
        .then((value) => print('Even more complete value=${value}'))
  ''');
}
