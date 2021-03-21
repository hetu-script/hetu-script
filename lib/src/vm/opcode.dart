abstract class HTOpCode {
  static const endOfFile = -1;

  /// 4 bytes
  static const signature = 250;

  /// uint8, uint8, uint16
  static const version = 251;

  /// 1 byte
  static const debug = 252;

  static const codeStart = 100;

  /// uint16 length of function
  static const funcStart = 101;

  /// uint32 line, uint32 column, uint8 symbolLength, symbol
  static const debugInfo = 200;
  static const error = 201; //

  static const returnValue = 0;
  static const endOfStatement = 1;

  static const constTable = 7;

  /// 1 byte of OpRandType, value
  static const local = 10;

  /// reg index => reg[index] = local
  static const register = 11; // 1 byte of index

  /// copy from to => reg[to] = reg[from]
  static const copy = 12;

  static const declare = 15;

  /// uint16 length of initializer
  static const initializerStart = 16;

  static const leftValue = 17;

  static const assign = 30; // 1 byte right value

  static const assignMultiply = 31;

  static const assignDevide = 32;

  static const assignAdd = 33;

  static const assignSubtract = 34;

  static const logicalOr = 42;

  static const logicalAnd = 43;

  static const equal = 44;

  static const notEqual = 45;

  static const lesser = 46;

  static const greater = 47;

  static const lesserOrEqual = 48;

  static const greaterOrEqual = 49;

  /// add left right store => reg[store] = reg[left] + reg[right]
  static const add = 59;

  /// subtract left right store => reg[store] = reg[left] + reg[right]
  static const subtract = 60;

  /// multiply left right store => reg[store] = reg[left] * reg[right]
  static const multiply = 61;

  /// devide left right store => reg[store] = reg[left] / reg[right]
  static const devide = 62;

  /// modulo left right store => reg[store] = reg[left] % reg[right]
  static const modulo = 64;

  /// modulo value store => reg[store] = -reg[value]
  static const negative = 65;

  /// modulo value store => reg[store] = !reg[value]
  static const logicalNot = 66;

  static const preIncrement = 68;

  static const preDecrement = 69;

  static const memberGet = 71;

  static const subGet = 72;

  static const call = 73;

  static const postIncrement = 74;

  static const postDecrement = 75;
}

abstract class HTLocalValueType {
  static const NULL = 0;
  static const boolean = 1;
  static const int64 = 2;
  static const float64 = 3;
  static const utf8String = 4;
  static const symbol = 5;
  static const group = 6;
  static const list = 7;
  static const map = 8;
}

abstract class HTErrorCode {
  static const binOp = 0;
}
