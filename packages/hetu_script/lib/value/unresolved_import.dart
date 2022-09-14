class UnresolvedImport {
  final String fromPath;

  final String? alias;

  final Set<String> showList;

  final bool isExported;

  UnresolvedImport(
    this.fromPath, {
    this.alias,
    this.showList = const {},
    this.isExported = true,
  });
}
