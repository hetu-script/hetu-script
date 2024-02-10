import '../struct/named_struct.dart';
import '../variable/variable.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../value/namespace/namespace.dart';
// import '../../shared/stringify.dart' as util;
import '../../utils/jsonify.dart' as util;
import '../../type/type.dart';
import '../../type/structural.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../declaration/declaration.dart';
import '../../common/internal_identifier.dart';
import '../../common/function_category.dart';

/// A prototype based dynamic object.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTEntity {
  static var structLiteralIndex = 0;

  final HTInterpreter interpreter;

  final String? id;

  HTStruct? prototype;

  final bool isRootPrototype;

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
      fieldTypes[key] = encap.valueType?.resolve(namespace) ??
          HTTypeAny(interpreter.lexicon.kAny);
    }
    return HTStructuralType(fieldTypes: fieldTypes, closure: namespace);
  }

  HTStruct(this.interpreter,
      {String? id,
      this.prototype,
      this.isRootPrototype = false,
      Map<String, dynamic>? fields,
      this.closure})
      : id = id ??
            '${InternalIdentifier.anonymousStruct}${structLiteralIndex++}',
        _fields = fields ?? {} {
    namespace = HTNamespace(
        lexicon: interpreter.lexicon, id: this.id, closure: closure);
    namespace.define(
      interpreter.lexicon.kThis,
      HTVariable(
        id: interpreter.lexicon.kThis,
        interpreter: interpreter,
        value: this,
        closure: namespace,
      ),
    );
  }

  Map<String, dynamic> toJson() => util.jsonifyStruct(this);

  // @override
  // String toString() {
  //   if (_fields.isNotEmpty) {
  //     final content =
  //         interpreter.lexicon.stringifyStructMembers(this, from: this);
  //     return '${interpreter.lexicon.codeBlockStart}\n$content${interpreter.lexicon.codeBlockEnd}';
  //   } else {
  //     return '${interpreter.lexicon.codeBlockStart}${interpreter.lexicon.codeBlockEnd}';
  //   }
  // }

  /// Check if this struct has the key in its own _fields
  bool containsKey(String? id) {
    return _fields.containsKey(id);
  }

  /// Check if this struct has the key in its own _fields or its prototypes' _fields
  @override
  bool contains(String? id) {
    if (id == null) {
      return false;
    }

    if (_fields.containsKey(id)) {
      return true;
    } else if (prototype != null && prototype!.contains(id)) {
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
      {bool override = false, bool throws = true}) {
    _fields[id] = value;
  }

  void delete(String id) {
    if (_fields.containsKey(id)) {
      _fields.remove(id);
    }
  }

  operator [](dynamic key) {
    return memberGet(key);
  }

  operator []=(dynamic key, dynamic value) {
    memberSet(key, value);
  }

  Iterable<String> get keys => _fields.keys;

  Iterable<dynamic> get values => _fields.values;

  /// The number of key/value pairs in the map.
  int get length => _fields.length;

  /// Whether there is no key/value pair in the map.
  bool get isEmpty => _fields.isEmpty;

  /// Whether there is at least one key/value pair in the map.
  bool get isNotEmpty => _fields.isNotEmpty;

  /// [isSelf] means wether this is called by the struct itself, or a recursive one
  @override
  dynamic memberGet(dynamic id, {String? from, bool isRecursivelyGet = false}) {
    if (id == null) {
      return null;
    }
    if (id is! String) {
      id = id.toString();
    }
    if (id == InternalIdentifier.prototype) {
      return prototype;
    }

    dynamic value;
    final getter = '${InternalIdentifier.getter}$id';
    final constructor = this.id != id
        ? '${InternalIdentifier.namedConstructorPrefix}$id'
        : InternalIdentifier.defaultConstructor;

    if (_fields.containsKey(id)) {
      if (interpreter.lexicon.isPrivate(id) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(id);
      }
      value = _fields[id];
    } else if (_fields.containsKey(getter)) {
      if (interpreter.lexicon.isPrivate(id) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(id);
      }
      value = _fields[getter]!;
    } else if (_fields.containsKey(constructor)) {
      if (interpreter.lexicon.isPrivate(id) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(id);
      }
      value = _fields[constructor]!;
    } else if (prototype != null) {
      value = prototype!.memberGet(id, from: from, isRecursivelyGet: true);
    }

    if (value is HTDeclaration) {
      value.resolve();
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
  bool memberSet(dynamic id, dynamic value,
      {String? from, bool defineIfAbsent = true, bool recursive = true}) {
    if (id == null) {
      throw HTError.nullSubSetKey();
    }
    if (id is! String) {
      id = id.toString();
    }
    if (id == InternalIdentifier.prototype) {
      if (value is! HTStruct) {
        throw HTError.notStruct();
      }
      prototype = value;
      return true;
    }

    final setter = '${InternalIdentifier.setter}$id';
    if (_fields.containsKey(id)) {
      if (interpreter.lexicon.isPrivate(id) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(id);
      }
      _fields[id] = value;
      return true;
    } else if (_fields.containsKey(setter)) {
      if (interpreter.lexicon.isPrivate(id) &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(id);
      }
      HTFunction func = _fields[setter]!;
      func.namespace = namespace;
      func.instance = this;
      func.call(positionalArgs: [value]);
      return true;
    } else if (recursive && prototype != null) {
      final success =
          prototype!.memberSet(id, value, from: from, defineIfAbsent: false);
      if (success) {
        return true;
      }
    }
    if (defineIfAbsent) {
      _fields[id] = value;
      return true;
    }
    return false;
  }

  @override
  dynamic subGet(dynamic id, {String? from}) => memberGet(id, from: from);

  @override
  void subSet(dynamic id, dynamic value, {String? from}) =>
      memberSet(id, value, from: from);

  // return a deep copy of this struct.
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

  // deep copy another struct then assign to this one.
  void assign(HTStruct other) {
    for (final key in other._fields.keys) {
      if (key.startsWith(interpreter.lexicon.internalPrefix)) continue;
      final value = other._fields[key];
      final copiedValue = interpreter.toStructValue(value);
      define(key, copiedValue);
    }
  }
}
