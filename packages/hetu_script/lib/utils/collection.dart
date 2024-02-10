import '../value/struct/struct.dart';

dynamic deepCopy(dynamic value) {
  if (value is Set) {
    final Set set = {};
    for (final item in value) {
      set.add(deepCopy(item));
    }
    return set;
  } else if (value is Iterable) {
    final List list = [];
    for (final item in value) {
      list.add(deepCopy(item));
    }
    return list;
  } else if (value is Map) {
    final Map map = {};
    for (final key in value.keys) {
      map[key] = deepCopy(value[key]);
    }
    return map;
  } else if (value is HTStruct) {
    return value.clone();
  } else {
    return value;
  }
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
