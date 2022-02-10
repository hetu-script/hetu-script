/// Operation code used by compiler.
abstract class HTOpCode {
  static const endOfCode = -1;
  static const local = 1;
  static const register = 2;
  static const copy = 3;
  static const skip = 4;
  static const anchor = 5;
  static const goto = 6;
  static const moveReg = 7;
  static const leftValue = 8;
  static const assertion = 9;
  static const throws = 10;
  static const loopPoint = 11;
  static const breakLoop = 12;
  static const continueLoop = 13;
  static const ifStmt = 14;
  static const whileStmt = 15;
  static const doStmt = 16;
  static const whenStmt = 17;
  static const block = 18;
  static const library = 19;
  static const file = 20;
  static const endOfStmt = 21;
  static const endOfBlock = 22;
  static const endOfExec = 23;
  static const endOfFunc = 24;
  static const endOfFile = 25;
  static const constIntTable = 30;
  static const constFloatTable = 31;
  static const constStringTable = 32;
  static const delete = 38;
  static const constDecl = 39;
  static const importExportDecl = 40;
  static const libraryDecl = 41;
  static const namespaceDecl = 42;
  static const typeAliasDecl = 43;
  static const funcDecl = 44;
  static const classDecl = 45;
  static const externalEnumDecl = 46;
  static const structDecl = 47;
  static const varDecl = 48;
  static const destructuringDecl = 49;
  static const assign = 50;
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
  static const add = 61;
  static const subtract = 62;
  static const multiply = 63;
  static const devide = 64;
  static const truncatingDevide = 65;
  static const modulo = 66;
  static const ifNull = 67;
  static const negative = 68;
  static const logicalNot = 69;
  static const memberGet = 70;
  static const subGet = 71;
  static const call = 72;
  static const typeOf = 73;
  static const typeAs = 74;
  static const typeIs = 75;
  static const typeIsNot = 76;
  static const isIn = 77;
  static const isNotIn = 78;
  static const lineInfo = 205;
}

/// Following [HTOpCode.local], tells the value type, used by compiler.
abstract class HTValueTypeCode {
  static const nullValue = 0;
  static const boolean = 1;
  static const constInt = 2;
  static const constFloat = 3;
  static const constString = 4;
  static const longString = 5;
  static const stringInterpolation = 6;
  static const identifier = 7;
  static const commaExprList = 8;
  static const list = 9;
  static const range = 10;
  static const group = 11;
  static const struct = 12;
  static const function = 13;
  static const type = 14;
}

abstract class StructObjFieldTypeCode {
  static const empty = 0;
  static const normal = 1;
  static const spread = 2;
}

abstract class DeletingTypeCode {
  static const local = 0;
  static const member = 1;
  static const sub = 2;
}

abstract class WhenCaseTypeCode {
  static const equals = 0;
  static const eigherEquals = 1;
  static const elementIn = 2;
}

enum HTConstantType {
  boolean,
  integer,
  float,
  string,
}

Type getConstantType(HTConstantType type) {
  switch (type) {
    case HTConstantType.boolean:
      return bool;
    case HTConstantType.integer:
      return int;
    case HTConstantType.float:
      return double;
    case HTConstantType.string:
      return String;
  }
}
