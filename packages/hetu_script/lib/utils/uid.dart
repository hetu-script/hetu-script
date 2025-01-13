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
String randomUID({int length = 4, bool withTime = false}) {
  assert(length >= 1);
  if (length < 15) {
    final id = ((Random().nextDouble() + 1) *
            int.parse('0x1'.padRight(length + 3, '0')))
        .truncate()
        .toRadixString(16)
        .substring(1);
    return '${withTime ? datetime() : ""}$id';
  } else {
    final output = StringBuffer();
    final c = (length / 12).floor();
    for (var i = 0; i < c; ++i) {
      output.write(randomUID(length: 12));
    }
    output.write(randomUID(length: length - c * 12));
    return '${withTime ? datetime() : ""}${output.toString()}';
  }
}

/// Get a random id consists by number.
String randomNID({int length = 8, bool withTime = false}) {
  assert(length >= 1);
  final r = Random();
  final output = StringBuffer();
  for (var i = 0; i < length; ++i) {
    output.write(r.nextInt(10));
  }
  return '${withTime ? datetime() : ""}${output.toString()}';
}

/// Get the date string from DateTime.now().
/// '20240307112422'
String datetime() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
}

String timestamp() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}
