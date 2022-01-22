import '../struct/named_struct.dart';
import '../variable/variable.dart';
import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../value/namespace/namespace.dart';
import '../../shared/stringify.dart' as util;
import '../../shared/jsonify.dart' as util;
import '../../type/type.dart';
import '../../type/structural_type.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';

/// A prototype based dynamic object.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTEntity {
  static var structLiteralIndex = 0;

  final Hetu interpreter;

  final String? id;

  HTStruct? prototype;

  HTNamedStruct? declaration;

  final Map<String, dynamic> _fields;

  late final HTNamespace namespace;

  final HTNamespace? closure;

  @override
  HTStructuralType get valueType {
    final fieldTypes = <String, HTType>{};
    for (final key in _fields.keys) {
      final value = _fields[key];
      final encap = interpreter.encapsulate(value);
      final unresolvedType = encap.valueType;
      fieldTypes[key] = unresolvedType.resolve(namespace);
    }
    return HTStructuralType(namespace, fieldTypes: fieldTypes);
  }

  HTStruct(this.interpreter,
      {String? id, this.prototype, Map<String, dynamic>? fields, this.closure})
      : id = id ?? '${Semantic.anonymousStruct}${structLiteralIndex++}',
        _fields = fields ?? {} {
    namespace = HTNamespace(id: this.id, closure: closure);
    namespace.define(HTLexicon.kThis, HTVariable(HTLexicon.kThis, value: this));
  }

  Map<String, dynamic> toJson() => util.jsonifyStruct(this);

  @override
  String toString() {
    if (_fields.isNotEmpty) {
      final content = util.stringifyStructMembers(this, from: this);
      return '${HTLexicon.bracesLeft}\n$content${HTLexicon.bracesRight}';
    } else {
      return '${HTLexicon.bracesLeft}${HTLexicon.bracesRight}';
    }
  }

  /// Check if this struct has the key in its own _fields
  bool containsKey(String varName) {
    return _fields.containsKey(varName);
  }

  /// Check if this struct has the key in its own _fields or its prototypes' _fields
  @override
  bool contains(String varName) {
    if (_fields.containsKey(varName)) {
      return true;
    } else if (prototype != null && prototype!.contains(varName)) {
      return true;
    } else {
      return false;
    }
  }

  void import(HTStruct other, {bool clone = false}) {
    for (final key in other._fields.keys) {
      if (!_fields.keys.contains(key)) {
        define(key, other._fields[key]);
      }
    }
  }

  void define(String id, dynamic value,
      {bool override = false, bool error = true}) {
    _fields[id] = value;
  }

  void delete(String id) {
    if (_fields.containsKey(id)) {
      _fields.remove(id);
    }
  }

  operator [](String key) {
    return memberGet(key);
  }

  operator []=(String key, dynamic value) {
    memberSet(key, value);
  }

  Iterable<String> get keys => _fields.keys;
  // .where((element) => !element.startsWith(HTLexicon.internalPrefix));

  Iterable<dynamic> get values => _fields.values;

  /// The number of key/value pairs in the map.
  int get length => _fields.length;

  /// Whether there is no key/value pair in the map.
  bool get isEmpty => _fields.isEmpty;

  /// Whether there is at least one key/value pair in the map.
  bool get isNotEmpty => _fields.isNotEmpty;

  /// [isSelf] means wether this is called by the struct itself, or a recursive one
  @override
  dynamic memberGet(String varName,
      {String? from, bool isRecursivelyGet = false}) {
    dynamic value;
    if (varName == Semantic.prototype) {
      return prototype;
    }
    final getter = '${Semantic.getter}$varName';
    final constructor = varName != id
        ? '${Semantic.constructor}${HTLexicon.privatePrefix}$varName'
        : Semantic.constructor;

    if (_fields.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      value = _fields[varName];
    } else if (_fields.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      value = _fields[getter]!;
    } else if (_fields.containsKey(constructor)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      value = _fields[constructor]!;
    } else if (prototype != null) {
      value = prototype!.memberGet(varName, from: from, isRecursivelyGet: true);
    }
    // assign the original struct as instance, not the prototype object
    if (!isRecursivelyGet) {
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
      {String? from, bool defineIfAbsent = true}) {
    final setter = '${Semantic.setter}$varName';
    if (_fields.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      _fields[varName] = varValue;
      return true;
    } else if (_fields.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      HTFunction func = _fields[setter]!;
      func.namespace = namespace;
      func.instance = this;
      func.call(positionalArgs: [varValue]);
      return true;
    } else if (prototype != null) {
      final success = prototype!
          .memberSet(varName, varValue, from: from, defineIfAbsent: false);
      if (success) {
        return true;
      }
    }
    if (defineIfAbsent) {
      _fields[varName] = varValue;
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
    final cloned =
        HTStruct(interpreter, prototype: prototype, closure: closure);
    for (final key in _fields.keys) {
      final value = _fields[key];
      final copiedValue = interpreter.toStructValue(value);
      cloned.define(key, copiedValue);
    }
    return cloned;
  }
}
