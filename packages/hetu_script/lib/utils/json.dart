import '../value/struct/struct.dart';

bool isJsonDataType(dynamic object) {
  if (object == null ||
      object is num ||
      object is bool ||
      object is String ||
      object is Map<String, dynamic> ||
      object is HTStruct ||
      object is Iterable) {
    return true;
  } else {
    return false;
  }
}

List<dynamic> jsonifyList(Iterable list) {
  final output = [];
  for (final value in list) {
    if (isJsonDataType(value)) {
      var converted = value;
      if (value is Iterable) {
        converted = jsonifyList(value);
      } else if (value is Map) {
        converted = jsonify(value);
      } else if (value is HTStruct) {
        converted = jsonifyStruct(value);
      }
      output.add(converted);
    }
  }
  return output;
}

Map<String, dynamic> jsonifyStruct(HTStruct struct, {HTStruct? from}) {
  final output = <String, dynamic>{};
  for (final key in struct.keys) {
    if (from != null && from.containsKey(key)) continue;
    var value = struct[key];
    // ignore none json data value
    if (isJsonDataType(value)) {
      if (value is Iterable) {
        value = jsonifyList(value);
      } else if (value is Map) {
        value = jsonify(value);
      } else if (value is HTStruct) {
        value = jsonifyStruct(value);
      }
      output[key] = value;
    }
  }
  // print prototype members, ignore the root object members
  // if (struct.prototype != null && !struct.prototype!.isPrototypeRoot) {
  //   final inherits = jsonifyStruct(struct.prototype!, from: from ?? struct);
  //   output.addAll(inherits);
  // }
  return output;
}

dynamic jsonify(dynamic value, {bool deep = true}) {
  if (value is Iterable) {
    if (deep) {
      return jsonifyList(value);
    } else {
      final list = [];
      for (final item in value) {
        list.add(item);
      }
      return list;
    }
  } else if (value is Map) {
    final Map<String, dynamic> map = {};
    for (final key in value.keys) {
      if (deep) {
        map[key.toString()] = jsonify(value[key]);
      } else {
        map[key.toString()] = value[key];
      }
    }
    return map;
  } else if (value is HTStruct) {
    if (deep) {
      return jsonifyStruct(value);
    } else {
      final Map<String, dynamic> map = {};
      for (final key in value.keys) {
        map[key.toString()] = value[key];
      }
      return map;
    }
  } else {
    return null;
  }
}
