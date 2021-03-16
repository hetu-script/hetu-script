abstract class HTOpCode {
  static const end = 0;
  static const constTable = 1;

  static const local = 2;
  static const add = 3;
  static const reg0 = 10;
  static const reg1 = 11;
  static const reg2 = 12;
  static const reg3 = 13;
  static const reg4 = 14;
  static const reg5 = 15;
  static const reg6 = 16;
  static const reg7 = 17;
  static const reg8 = 18;
  static const reg9 = 19;

  static const error = 205;
}

abstract class HTOpRandType {
  static const constInt64 = 1;
  static const constFloat64 = 2;
  static const constUtf8String = 3;
}

abstract class HTErrorCode {
  static const binOp = 26;
}
