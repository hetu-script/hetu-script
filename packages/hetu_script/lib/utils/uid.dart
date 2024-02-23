import 'dart:math';

String randomUUID() {
  final output = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
      .replaceAllMapped(RegExp('[xy]'), (match) {
    final random = (Random().nextDouble() * 16).floor();
    return (match.group(0) == 'x' ? random : (random & 0x3) | 0x8)
        .toRadixString(16);
  });
  return output;
}

String randomUID4([int? repeat]) {
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
