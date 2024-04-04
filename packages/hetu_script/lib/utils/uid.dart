import 'dart:math';

/// Get a random UUID
String randomUUID() {
  final output = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
      .replaceAllMapped(RegExp('[xy]'), (match) {
    final random = (Random().nextDouble() * 16).floor();
    return (match.group(0) == 'x' ? random : (random & 0x3) | 0x8)
        .toRadixString(16);
  });
  return output;
}

/// Get a random id consists by number and letters.
String randomUID([int? length]) {
  length ??= 4;
  assert(length >= 1);
  if (length < 15) {
    final id = ((Random().nextDouble() + 1) *
            int.parse('0x1'.padRight(length + 3, '0')))
        .truncate()
        .toRadixString(16)
        .substring(1);
    return id;
  } else {
    final output = StringBuffer();
    final c = (length / 12).floor();
    for (var i = 0; i < c; ++i) {
      output.write(randomUID(12));
    }
    output.write(randomUID(length - c * 12));
    return output.toString();
  }
}

/// Get a random id consists by number.
String randomNID([int? length]) {
  length ??= 8;
  assert(length >= 1);
  final r = Random(DateTime.now().millisecondsSinceEpoch);
  final output = StringBuffer();
  for (var i = 0; i < length; ++i) {
    if (i == 0) {
      output.write(r.nextInt(9) + 1);
    } else {
      output.write(r.nextInt(10));
    }
  }
  return output.toString();
}
