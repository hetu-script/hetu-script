import 'package:hetu_script/value/struct/named_struct.dart';
import 'package:hetu_script/value/variable/variable.dart';

import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../value/namespace/namespace.dart';
import '../../shared/stringify.dart' as util;
import '../../shared/jsonify.dart' as util;
import '../../type/structural_type.dart';
import '../../error/error.dart';

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

  HTNamedStruct? definition;

  final fields = <String, dynamic>{};

  HTNamespace namespace;

  HTNamespace? get closure => namespace.closure;

  @override
  final HTStructuralType valueType;

  HTStruct(HTNamespace closure,
      {this.id, this.prototype, Map<String, dynamic>? fields})
      : namespace = HTNamespace(id: id ?? HTLexicon.kStruct, closure: closure),
        valueType = HTStructuralType() {
    namespace.define(HTLexicon.kThis, HTVariable(HTLexicon.kThis, value: this));
    if (fields != null) {
      this.fields.addAll(fields);
    }
  }

  Map<String, dynamic> toJson() => util.jsonifyStruct(this);

  @override
  String toString() {
    final content = util.stringifyStructMembers(this, from: this);
    return '{\n$content}';
  }

  /// Check if this struct has the key in its own fields
  bool owns(String varName) {
    return fields.containsKey(varName);
  }

  /// Check if this struct has the key in its own fields or its prototypes' fields
  @override
  bool contains(String varName) {
    if (fields.containsKey(varName)) {
      return true;
    } else if (prototype != null && prototype!.contains(varName)) {
      return true;
    } else {
      return false;
    }
  }

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
    if (fields.containsKey(id)) {
      fields.remove(id);
    }
  }

  /// [isSelf] means wether this is called by the struct itself, or a recursive one
  @override
  dynamic memberGet(String varName, {String? from, bool isSelf = true}) {
    dynamic value;
    if (varName == Semantic.prototype) {
      return prototype;
    }
    final getter = '${Semantic.getter}$varName';

    if (fields.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      value = fields[varName];
    } else if (fields.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      value = fields[getter]!;
    } else if (prototype != null) {
      value = prototype!.memberGet(varName, from: from, isSelf: false);
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
  bool memberSet(String varName, dynamic varValue,
      {String? from, bool define = true}) {
    final setter = '${Semantic.setter}$varName';
    if (fields.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      fields[varName] = varValue;
      return true;
    } else if (fields.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      HTFunction func = fields[setter]!;
      func.namespace = namespace;
      func.instance = this;
      func.call(positionalArgs: [varValue]);
      return true;
    } else if (prototype != null) {
      final success =
          prototype!.memberSet(varName, varValue, from: from, define: false);
      if (success) {
        return true;
      }
    }
    if (define) {
      fields[varName] = varValue;
      return true;
    }
    return false;
  }

  @override
  dynamic subGet(dynamic varName, {String? from}) =>
      memberGet(varName.toString(), from: from);

  @override
  void subSet(dynamic varName, dynamic varValue, {String? from}) =>
      memberSet(varName.toString(), varValue, from: from);

  HTStruct clone() {
    final cloned = HTStruct(closure!, prototype: prototype);
    for (final key in fields.keys) {
      final value = fields[key];
      final copiedValue = toStructValue(value, closure!);
      cloned.define(key, copiedValue);
    }
    return cloned;
  }
}
