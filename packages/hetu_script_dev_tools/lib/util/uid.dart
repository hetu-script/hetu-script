import 'dart:math';

String uid4() {
  return ((1.0 + Random.secure().nextDouble()) * 0x10000)
      .floor()
      .toRadixString(16)
      .substring(1);
}
