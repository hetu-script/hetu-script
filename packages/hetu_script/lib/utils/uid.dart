import 'dart:math';

String uid4([int? repeat]) {
  repeat ??= 1;
  final sb = StringBuffer();
  for (var i = 0; i < repeat; ++i) {
    sb.write(((Random().nextDouble() + 1) * 0x10000)
        .truncate()
        .toRadixString(16)
        .substring(1));
  }
  return sb.toString();
}
