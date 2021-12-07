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

  static const library = 31;

  static const module = 32;

  static const constTable = 33;

  static const importDecl = 40;

  static const exportDecl = 41;

  static const libraryDecl = 42;

  static const namespaceDecl = 43;

  static const typeAliasDecl = 44;

  static const funcDecl = 45;

  static const classDecl = 46;

  static const externalEnumDecl = 47;

  static const structDecl = 48;

  static const varDecl = 49;

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
  static const meta = 200;

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
  static const string = 5;
  static const stringInterpolation = 6;
  static const identifier = 7;
  static const subValue = 8;
  static const group = 9;
  static const list = 10;
  static const struct = 11;
  static const function = 12;
  static const type = 13;
}

/// Identifier type code.
abstract class IdentifierType {
  static const normal = 0;
  static const member = 1;
  static const sub = 2;
}

abstract class StructObjFieldType {
  static const normal = 0;
  static const spread = 1;
  static const identifier = 2;
}

// abstract class FieldType {
//   static const variable = 0;
//   static const function = 1;
// }
