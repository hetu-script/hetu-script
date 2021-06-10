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

bool isEqual(dynamic a, dynamic b) {
  if ((a is List) && (b is List)) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; ++i) {
      if (!isEqual(a[i], b[i])) return false;
    }
    return true;
  } else if ((a is Map) && (b is Map)) {
    if (a.length != b.length) return false;
    if (!isEqual(a.keys, b.keys)) return false;
    for (final k in a.keys) {
      if (!isEqual(a[k], b[k])) return false;
    }
    return true;
  } else if ((a is Set) && (b is Set)) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  } else {
    return a == b;
  }
}

String getEnumString(Object item) {
  final string = item.toString();
  final index = string.lastIndexOf('.');
  if (index != -1) {
    return string.substring(index + 1);
  } else {
    return string;
  }
}
