abstract class HTOpCode {
  static const endOfFile = -1;

  /// 4 bytes
  static const signature = 200;

  /// uint8, uint8, uint16
  static const version = 201;

  /// 1 byte
  static const debug = 202;

  /// uint32 line, uint32 column, uint8 symbolLength, symbol
  static const debugInfo = 203;
  static const error = 204; //

  static const endOfStmt = 210;
  static const endOfExec = 211;

  static const constTable = 7;
  static const declTable = 8;

  /// 1 byte of OpRandType, value
  static const local = 10;

  /// reg index => reg[index] = local
  static const register = 11; // 1 byte of index

  /// copy from to => reg[to] = reg[from]
  static const copy = 12;

  static const leftValue = 14;

  // static const varDecl = 15;

  /// uint16 length of initializer
  static const varInit = 16;

  // static const funcDecl = 17;

  // // TODO: error when reach limit
  // /// uint16 length of function
  static const funcDef = 18;

  // static const classDecl = 19;

  // /// uint16 length of class
  // static const classDefStart = 20;

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

abstract class HTValueTypeCode {
  static const NULL = 0;
  static const boolean = 1;
  static const int64 = 2;
  static const float64 = 3;
  static const utf8String = 4;
  static const symbol = 5;
  static const group = 6;
  static const list = 7;
  static const map = 8;
  static const function = 9;
}

/// Extern function is not a [FunctionType]
abstract class HTFuncTypeCode {
  static const normal = 0;
  static const constructor = 1;
  static const getter = 2;
  static const setter = 3;
  static const literal = 4; // function expression with no function name
  static const nested = 5; // function within function, may with name
}

abstract class HTClassTypeCode {
  static const normal = 0;
  static const nested = 1;
  static const abstracted = 2;
  static const interface = 3;
  static const mix_in = 4;
  static const extern = 5;
}

abstract class HTErrorCode {
  static const binOp = 0;
}
