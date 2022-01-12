/// Compute line starts for the given [content].
/// Lines end with `\r`, `\n` or `\r\n`.
List<int> computeLineStarts(String content) {
  final lineStarts = <int>[0];
  final length = content.length;
  int unit;
  for (var index = 0; index < length; index++) {
    unit = content.codeUnitAt(index);
    // Special-case \r\n.
    if (unit == 0x0D /* \r */) {
      // Peek ahead to detect a following \n.
      if ((index + 1 < length) && content.codeUnitAt(index + 1) == 0x0A) {
        // Line start will get registered at next index at the \n.
      } else {
        lineStarts.add(index + 1);
      }
    }
    // \n
    if (unit == 0x0A) {
      lineStarts.add(index + 1);
    }
  }
  return lineStarts;
}
