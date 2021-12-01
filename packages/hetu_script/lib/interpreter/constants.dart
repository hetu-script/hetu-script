/// Operation code used by compiler.
abstract class HTOpCode {
  static const endOfFile = -1;

  /// 1 byte of OpRandType, value
  static const local = 1;

  /// reg index => reg[key] = local
  static const register = 2; // 1 byte of index

  /// copy from to => reg[to] = reg[from]
  static const copy = 3;

  // static const leftValue = 4;

  /// ip = ip + [distance], distance could be negative
  static const skip = 4;

  static const anchor = 5;

  /// ip = pos, distance could be negative
  static const goto = 6;

  static const moveReg = 7;

  static const leftValue = 8;

  static const loopPoint = 10;

  static const breakLoop = 11;

  static const continueLoop = 12;

  static const endOfStmt = 20;

  static const endOfBlock = 21;

  static const endOfExec = 22;

  static const endOfFunc = 23;

  static const endOfModule = 24;

  static const ifStmt = 26;

  static const whileStmt = 27;

  static const doStmt = 28;

  static const whenStmt = 29;

  static const block = 30;

  static const module = 31;

  static const constTable = 32;

  static const importDecl = 40;

  static const exportDecl = 41;

  static const exportImportDecl = 42;

  static const libraryDecl = 43;

  static const namespaceDecl = 44;

  static const typeAliasDecl = 45;

  static const funcDecl = 46;

  static const classDecl = 47;

  static const varDecl = 48;

  static const structDecl = 49;

  static const assign = 50; // 1 byte right value

  static const memberSet = 51;

  static const subSet = 52;

  static const logicalOr = 53;

  static const logicalAnd = 54;

  static const equal = 55;

  static const notEqual = 56;

  static const lesser = 57;

  static const greater = 58;

  static const lesserOrEqual = 59;

  static const greaterOrEqual = 60;

  static const typeAs = 61;

  static const typeIs = 62;

  static const typeIsNot = 63;

  /// add left right store => reg[store] = reg[left] + reg[right]
  static const add = 64;

  /// subtract left right store => reg[store] = reg[left] + reg[right]
  static const subtract = 65;

  /// multiply left right store => reg[store] = reg[left] * reg[right]
  static const multiply = 66;

  /// devide left right store => reg[store] = reg[left] / reg[right]
  static const devide = 67;

  /// modulo left right store => reg[store] = reg[left] % reg[right]
  static const modulo = 68;

  /// modulo value store => reg[store] = -reg[valueOf]
  static const negative = 69;

  /// modulo value store => reg[store] = !reg[valueOf]
  static const logicalNot = 70;

  static const typeOf = 71;

  static const memberGet = 72;

  static const subGet = 73;

  static const call = 74;

  /// 4 bytes
  static const signature = 200;

  static const library = 201;

  /// uint8, uint8, uint16
  static const version = 202;

  static const author = 203;

  static const created = 204;

  /// uint16 line & column
  static const lineInfo = 205;
}

/// Following a local operation, tells the value type, used by compiler.
abstract class HTValueTypeCode {
  static const NULL = 0;
  static const boolean = 1;
  static const constInt = 2;
  static const constFloat = 3;
  static const constString = 4;
  static const stringInterpolation = 5;
  static const identifier = 6;
  static const subValue = 7;
  static const group = 8;
  static const list = 9;
  static const struct = 10;
  static const function = 11;
  static const type = 12;
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

/// Identifier type code.
abstract class IdentifierType {
  static const normal = 0;
  static const member = 1;
  static const sub = 2;
}

// abstract class FieldType {
//   static const variable = 0;
//   static const function = 1;
// }
