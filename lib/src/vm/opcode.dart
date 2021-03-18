abstract class HTOpCode {
  static const subReturn = 0;
  static const endOfStatement = 1;
  static const debugInfo = 2;
  static const line = 3;
  static const column = 4;
  static const filename = 5;

  static const constTable = 10;

  static const literal = 15;

  /// reg index => reg[index] = local
  static const register = 20;

  /// copy from to => reg[to] = reg[from]
  static const copy = 21;

  /// add left right store => reg[store] = reg[left] + reg[right]
  static const add = 40;

  /// subtract left right store => reg[store] = reg[left] + reg[right]
  static const subtract = 41;

  /// multiply left right store => reg[store] = reg[left] * reg[right]
  static const multiply = 42;

  /// devide left right store => reg[store] = reg[left] / reg[right]
  static const devide = 43;

  /// modulo left right store => reg[store] = reg[left] % reg[right]
  static const modulo = 44;

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
  static const binOp = 0;
}
