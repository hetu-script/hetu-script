/// Execution jump point, this is a reletive jump from the current ip of the bytecode module.
/// For absolute jumpo point, will use HTOpCode.anchor and HTOpCode.goto.
mixin GotoInfo {
  late final String file;
  late final String module;
  late final int? ip;
  late final int? line;
  late final int? column;
}
