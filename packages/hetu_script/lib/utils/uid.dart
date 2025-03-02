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
  final dt = withTime ? datetime() + '-' : '';
  if (length < 15) {
    final id = ((Random().nextDouble() + 1) *
            int.parse('0x1'.padRight(length + 3, '0')))
        .truncate()
        .toRadixString(16)
        .substring(1);
    return '$dt$id';
  } else {
    final output = StringBuffer();
    final c = (length / 12).floor();
    for (var i = 0; i < c; ++i) {
      output.write(randomUID(length: 12));
    }
    output.write(randomUID(length: length - c * 12));
    return '$dt${output.toString()}';
  }
}

/// Get a random id consists by number.
String randomNID({int length = 8, bool withTime = false}) {
  assert(length >= 1);
  final dt = withTime ? datetime() + '-' : '';
  final r = Random();
  final output = StringBuffer();
  for (var i = 0; i < length; ++i) {
    output.write(r.nextInt(10));
  }
  return '$dt${output.toString()}';
}

/// Get the date string from DateTime.now().
/// '20240307112422357516'
String datetime() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${now.millisecond.toString()}${now.microsecond.toString()}';
}

String timestamp() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}
