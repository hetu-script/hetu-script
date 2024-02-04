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
