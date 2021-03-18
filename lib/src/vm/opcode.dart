abstract class HTOpCode {
  static const endOfFile = 0;
  static const endOfLine = 1;
  static const debugInfo = 2;
  static const line = 3;
  static const column = 4;
  static const filename = 5;

  static const constTable = 10;

  static const literal = 15;

  static const reg0 = 20;
  static const reg1 = 21;
  static const reg2 = 22;
  static const reg3 = 23;
  static const reg4 = 24;
  static const reg5 = 25;
  static const reg6 = 26;
  static const reg7 = 27;
  static const reg8 = 28;
  static const reg9 = 29;

  static const add = 40;

  static const error = 205;
}

abstract class HTOpRandType {
  static const nil = 0;
  static const boolean = 1;
  static const int64 = 2;
  static const float64 = 3;
  static const utf8String = 4;
}

abstract class HTErrorCode {
  static const binOp = 26;
}
