import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../declaration/namespace/namespace.dart';
import '../../value/const.dart';
import '../../shared/stringify.dart' as util;
import '../../shared/jsonify.dart' as util;

/// A prototype based dynamic object.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTEntity {
  static dynamic toStructValue(dynamic value, HTNamespace closure) {
    if (value is Iterable) {
      final list = [];
      for (final item in value) {
        final result = toStructValue(item, closure);
        list.add(result);
      }
      return list;
    } else if (value is Map) {
      final struct = HTStruct(closure);
      for (final key in value.keys) {
        final fieldKey = key.toString();
        final fieldValue = toStructValue(value[key], closure);
        struct.define(fieldKey, fieldValue);
      }
      return struct;
    } else if (value is HTStruct) {
      return value.clone();
    } else {
      return value;
    }
  }

  static HTStruct fromJson(Map<String, dynamic> jsonData, HTNamespace closure) {
    final struct = HTStruct(closure);
    for (final key in jsonData.keys) {
      var value = toStructValue(jsonData[key], closure);
      struct.define(key, value);
    }
    return struct;
  }

  String? id;

  HTStruct? prototype;

  final fields = <String, dynamic>{};

  HTNamespace namespace;

  HTNamespace? get closure => namespace.closure;

  HTStruct(HTNamespace closure,
      {this.id, this.prototype, Map<String, dynamic>? fields})
      : namespace = HTNamespace(id: id ?? HTLexicon.STRUCT, closure: closure) {
    namespace.define(HTLexicon.THIS, HTConst(HTLexicon.THIS, value: this));
    if (fields != null) {
      this.fields.addAll(fields);
    }
  }

  Map<String, dynamic> toJson() => util.jsonifyStruct(this);

  @override
  String toString() {
    final content = util.stringifyStruct(this, from: this);
    return '{\n$content}';
  }

  /// Check if this struct has the key in its own fields
  bool owns(String varName) {
    if (fields.containsKey(varName)) {
      return true;
    }
    return false;
  }

  /// Check if this struct has the key in its own fields or its prototypes' fields
  @override
  bool contains(String varName) {
    if (fields.containsKey(varName)) {
      return true;
    } else if (prototype != null && prototype!.contains(varName)) {
      return true;
    }
    return false;
  }

  bool get isEmpty => fields.isEmpty;

  bool get isNotEmpty => fields.isNotEmpty;

  void import(HTStruct other, {bool clone = false}) {
    for (final key in other.fields.keys) {
      if (!fields.keys.contains(key)) {
        define(key, other.fields[key]);
      }
    }
  }

  void define(String id, dynamic value,
      {bool override = false, bool error = true}) {
    fields[id] = value;
  }

  void delete(String id) {
    fields.remove(id);
  }

  /// [isSelf] means wether this is called by the struct itself, or a recursive one
  @override
  dynamic memberGet(String varName, {bool isSelf = true}) {
    dynamic value;
    if (varName == SemanticNames.prototype) {
      return prototype;
    }
    if (fields.containsKey(varName)) {
      value = fields[varName];
    } else if (prototype != null) {
      value = prototype!.memberGet(varName, isSelf: false);
    }
    // assign the original struct as instance, not the prototype object
    if (isSelf) {
      if (value is HTFunction) {
        value.namespace = namespace;
        value.instance = this;
        if (value.category == FunctionCategory.getter) {
          value = value.call();
        }
      }
    }
    return value;
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    if (fields.containsKey(varName)) {
      fields[varName] = varValue;
      return;
    } else if (prototype != null && prototype!.contains(varName)) {
      prototype!.memberSet(varName, varValue);
      return;
    } else {
      fields[varName] = varValue;
    }
  }

  @override
  dynamic subGet(dynamic varName) => memberGet(varName.toString());

  @override
  void subSet(dynamic varName, dynamic varValue) =>
      memberSet(varName.toString(), varValue);

  HTStruct clone() {
    final cloned = HTStruct(closure!);
    for (final key in fields.keys) {
      final value = fields[key]!;
      final copiedValue = toStructValue(value, closure!);
      cloned.define(key, copiedValue);
    }
    return cloned;
  }
}
