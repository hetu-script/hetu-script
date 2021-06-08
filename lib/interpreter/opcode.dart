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
  static const skip = 4;

  static const anchor = 5;

  /// ip = pos, distance could be negative
  static const goto = 6;

  static const module = 7;

  /// uint16 line & column
  static const lineInfo = 8;

  static const singleComment = 9;

  static const multilineComment = 10;

  static const leftValue = 11;

  static const loopPoint = 12;

  static const breakLoop = 13;

  static const continueLoop = 14;

  static const block = 15;

  static const endOfBlock = 16;

  static const endOfStmt = 17;

  static const endOfExec = 18;

  static const endOfFunc = 19;

  static const endOfModule = 20;

  static const constTable = 21;

  static const enumDecl = 22;

  static const funcDecl = 23;

  static const classDecl = 24;

  static const varDecl = 25;

  static const ifStmt = 30;

  static const whileStmt = 31;

  static const doStmt = 32;

  static const whenStmt = 33;

  static const assign = 40; // 1 byte right value

  static const memberSet = 41;

  static const subSet = 42;

  static const logicalOr = 43;

  static const logicalAnd = 44;

  static const equal = 45;

  static const notEqual = 46;

  static const lesser = 47;

  static const greater = 48;

  static const lesserOrEqual = 49;

  static const greaterOrEqual = 50;

  static const typeAs = 51;

  static const typeIs = 52;

  static const typeIsNot = 53;

  /// add left right store => reg[store] = reg[left] + reg[right]
  static const add = 54;

  /// subtract left right store => reg[store] = reg[left] + reg[right]
  static const subtract = 55;

  /// multiply left right store => reg[store] = reg[left] * reg[right]
  static const multiply = 56;

  /// devide left right store => reg[store] = reg[left] / reg[right]
  static const devide = 57;

  /// modulo left right store => reg[store] = reg[left] % reg[right]
  static const modulo = 58;

  /// modulo value store => reg[store] = -reg[valueOf]
  static const negative = 60;

  /// modulo value store => reg[store] = !reg[valueOf]
  static const logicalNot = 61;

  static const memberGet = 65;

  static const subGet = 66;

  static const call = 67;

  /// 4 bytes
  static const signature = 200;

  /// uint8, uint8, uint16
  static const version = 201;

  static const author = 203;

  static const moduleName = 204;

  static const created = 205;
}

/// Following a local operation, tells the value type, used by compiler.
abstract class HTValueTypeCode {
  static const NULL = 0;
  static const boolean = 1;
  static const constInt = 2;
  static const constFloat = 3;
  static const constString = 4;
  static const symbol = 5;
  static const subValue = 6;
  static const group = 7;
  static const list = 8;
  static const map = 9;
  static const function = 10;
  static const type = 11;
  static const funcType = 11;
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
// abstract class HTClassTypeCode {
//   static const normal = 0;
//   static const nested = 1;
//   static const abstracted = 2;
//   static const interface = 3;
//   static const mix_in = 4;
// }

/// Current symbol type.
abstract class SymbolType {
  static const normal = 0;
  static const member = 1;
  static const sub = 2;
}
