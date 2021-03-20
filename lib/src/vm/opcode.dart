abstract class HTOpCode {
  static const subReturn = 0;
  static const endOfStatement = 1;
  static const debugInfo = 2;
  static const line = 3;
  static const column = 4;
  static const filename = 5;

  static const constTable = 10;

  static const literal = 15;

  static const symbol = 16;

  /// reg index => reg[index] = local
  static const register = 20;

  /// copy from to => reg[to] = reg[from]
  static const copy = 21;

  static const assign = 30;

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

  static const error = 205;
}

abstract class HTOpRandType {
  static const nil = 0;
  static const boolean = 1;
  static const int64 = 2;
  static const float64 = 3;
  static const utf8String = 4;
  static const symbol = 5;
}

abstract class HTErrorCode {
  static const binOp = 0;
}
