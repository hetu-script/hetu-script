enum FunctionType {
  normal,
  constructor,
  getter,
  setter,
  literal, // function expression with no function name
  nested, // function within function, may with name
}

enum ClassType {
  normal,
  nested,
  abstracted,
  interface,
  mix_in,
  extern,
}

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 库脚本中只能出现变量、类、函数、import和export语句
  module,

  /// 函数语句块中只能出现变量声明、控制语句、函数声明、函数调用和表达式
  function,

  /// 类定义中只能出现变量、函数和嵌套类声明
  klass,
}

class HTVersion {
  late final int major;
  late final int minor;
  late final int patch;
  HTVersion(this.major, this.minor, this.patch);

  @override
  String toString() => '$major.$minor.$patch';
}
