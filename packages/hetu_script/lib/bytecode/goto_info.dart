/// Execution jump point, this is a reletive jump from the current ip of the bytecode module.
/// For absolute jumpo point, will use HTOpCode.anchor and HTOpCode.goto.
mixin GotoInfo {
  late final String fileName;
  late final String moduleName;
  late final int? definitionIp;
  late final int? definitionLine;
  late final int? definitionColumn;
}
