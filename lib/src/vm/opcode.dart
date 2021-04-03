/// Operation code used by compiler.
abstract class HTOpCode {
  static const endOfFile = -1;

  /// 1 byte of OpRandType, value
  static const local = 1;

  /// reg index => reg[index] = local
  static const register = 2; // 1 byte of index

  /// copy from to => reg[to] = reg[from]
  static const copy = 3;

  // static const leftValue = 4;

  /// ip = ip + [distance], distance could be negative
  static const goto = 4;

  /// uint16 line & column
  static const debugInfo = 5;

  static const objectSymbol = 6;

  static const loopPoint = 7;

  static const breakLoop = 8;

  static const continueLoop = 9;

  static const block = 10;

  static const endOfBlock = 11;

  static const endOfStmt = 12;

  static const endOfExec = 13;

  static const endOfFunc = 14;

  static const constTable = 18;

  static const declTable = 19;

  static const ifStmt = 21;

  static const whileStmt = 22;

  static const doStmt = 23;

  static const whenStmt = 24;

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

  static const typeIs = 50;

  static const typeIsNot = 51;

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

  /// modulo value store => reg[store] = -reg[valueOf]
  static const negative = 65;

  /// modulo value store => reg[store] = !reg[valueOf]
  static const logicalNot = 66;

  static const preIncrement = 68;

  static const preDecrement = 69;

  static const memberGet = 71;

  static const subGet = 72;

  static const call = 73;

  static const postIncrement = 74;

  static const postDecrement = 75;

  /// 4 bytes
  static const signature = 200;

  /// uint8, uint8, uint16
  static const version = 201;

  /// 1 byte
  static const debug = 202;

  static const author = 203;

  static const moduleName = 204;

  static const created = 205;
}

/// Following a local operation, tells the value type, used by compiler.
abstract class HTValueTypeCode {
  static const NULL = 0;
  static const boolean = 1;
  static const int64 = 2;
  static const float64 = 3;
  static const utf8String = 4;
  static const symbol = 5;
  static const group = 6;
  static const tuple = 7;
  static const list = 8;
  static const map = 9;
  static const function = 10;
  static const typeid = 11;
}

/// Function type code.
abstract class HTFunctionTypeCode {
  static const normal = 0;
  static const constructor = 1;
  static const getter = 2;
  static const setter = 3;
  static const literal = 4; // function expression with no function name
  static const nested = 5; // function within function, may with name
}

/// Class type code.
abstract class HTClassTypeCode {
  static const normal = 0;
  static const nested = 1;
  static const abstracted = 2;
  static const interface = 3;
  static const mix_in = 4;
  static const extern = 5;
}

/// Current symbol type.
abstract class SymbolType {
  static const normal = 0;
  static const member = 1;
  static const sub = 2;
}
