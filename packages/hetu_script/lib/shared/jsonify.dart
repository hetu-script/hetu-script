import '../value/struct/struct.dart';

bool isJsonDataType(dynamic object) {
  if (object == null ||
      object is num ||
      object is bool ||
      object is String ||
      object is HTStruct ||
      object is Iterable ||
      object is Map<String, dynamic>) {
    return true;
  } else {
    return false;
  }
}

List<dynamic> jsonifyList(Iterable list) {
  final output = [];
  for (final value in list) {
    if (value is HTStruct) {
      output.add(jsonifyStruct(value));
    } else if (value is Iterable) {
      output.add(jsonifyList(value));
    } else if (isJsonDataType(value)) {
      output.add(value);
    }
  }
  return output;
}

Map<String, dynamic> jsonifyStruct(HTStruct struct) {
  final output = <String, dynamic>{};
  for (final key in struct.keys) {
    var value = struct[key];
    // ignore none json data value
    if (isJsonDataType(value)) {
      if (value is Iterable) {
        value = jsonifyList(value);
      } else if (value is HTStruct) {
        value = jsonifyStruct(value);
      }
      output[key] = value;
    }
  }
  // print prototype members, ignore the root object members
  // if (struct.prototype != null && !struct.isRootPrototype) {
  //   final inherits = jsonifyStruct(struct.prototype!);
  //   output.addAll(inherits);
  // }
  return output;
}
