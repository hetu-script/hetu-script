enum FunctionType {
  normal,
  method,
  constructor,
  getter,
  setter,
  literal, // function expression with no function name
  nested, // function within function, may with name
}

enum ExternalFuncDeclType {
  none,
  standalone,
  klass,
}

enum ClassType {
  normal,
  nested,
  abstracted,
  interface,
  mixIn,
  extern,
}

enum CodeType {
  expression,

  /// 库脚本中只能出现变量、类、函数、import和export语句
  module,

  /// 类定义中只能出现变量和函数
  klass,

  function,

  /// 函数语句块中只能出现变量声明、控制语句、函数声明、函数调用和表达式
  block,

  /// 脚本中可以出现所有的语句
  script,
}

class HTVersion {
  late final int major;
  late final int minor;
  late final int patch;
  HTVersion(this.major, this.minor, this.patch);

  @override
  String toString() => '$major.$minor.$patch';
}

enum ReferrenceType {
  normal,
  member,
  sub,
}

class HTRegIdx {
  static const value = 0;
  static const symbol = 1;
  static const objectSymbol = 2;
  static const refType = 3;
  static const loopCount = 4;
  static const assign = 5;
  static const orLeft = 6;
  static const orRight = 7;
  static const andLeft = 8;
  static const andRight = 9;
  static const equalLeft = 10;
  static const equalRight = 11;
  static const relationLeft = 12;
  static const relationRight = 13;
  static const addLeft = 14;
  static const addRight = 15;
  static const multiplyLeft = 16;
  static const multiplyRight = 17;
  static const postfixObject = 18;
  static const postfixKey = 19;

  static const length = 20;
}
