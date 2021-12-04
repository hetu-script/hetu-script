import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../declaration/namespace/namespace.dart';
import '../../value/const.dart';
import '../../shared/stringify.dart' as util;

/// A prototype based dynamic object.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTEntity {
  static var _curIndentCount = 0;

  static String _curIndent() {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(HTLexicon.indentSpaces);
      --i;
    }
    return output.toString();
  }

  /// Print all members of a struct object to a string.
  static String stringify(HTStruct struct, {HTStruct? from}) {
    final output = StringBuffer();
    ++_curIndentCount;
    for (var i = 0; i < struct.fields.length; ++i) {
      final key = struct.fields.keys.elementAt(i);
      if (from != null && from != struct) {
        if (from.contains(key)) {
          continue;
        }
      }
      output.write(_curIndent());
      final value = struct.fields[key];
      final valueBuffer = StringBuffer();
      if (value is HTStruct) {
        final content = stringify(value, from: from);
        valueBuffer.writeln(HTLexicon.curlyLeft);
        valueBuffer.write(content);
        valueBuffer.write(_curIndent());
        valueBuffer.write(HTLexicon.curlyRight);
      } else {
        final valueString = util.stringify(value);
        valueBuffer.write(valueString);
      }
      output.write('$key${HTLexicon.colon} $valueBuffer');
      if (i < struct.fields.length - 1) {
        output.write(HTLexicon.comma);
      }
      output.writeln();
    }
    --_curIndentCount;
    if (struct.prototype != null &&
        struct.prototype!.id != HTLexicon.prototype) {
      final inherits = stringify(struct.prototype!);
      output.write(inherits);
    }
    return output.toString();
  }

  static bool _isJsonDataType(dynamic object) {
    if (object == null ||
        object is num ||
        object is bool ||
        object is String ||
        object is HTStruct) {
      return true;
    } else if (object is Iterable) {
      for (final value in object) {
        if (!_isJsonDataType(value)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  static List<dynamic> _jsonifyList(Iterable list) {
    final output = [];
    for (final value in list) {
      if (value is HTStruct) {
        output.add(jsonify(value));
      } else if (value is Iterable) {
        output.add(_jsonifyList(value));
      } else {
        output.add(value);
      }
    }
    return output;
  }

  static Map<String, dynamic> jsonify(HTStruct struct) {
    final output = <String, dynamic>{};
    for (final key in struct.fields.keys) {
      var value = struct.fields[key];
      // ignore none json data value
      if (_isJsonDataType(value)) {
        if (value is Iterable) {
          value = _jsonifyList(value);
        } else if (value is HTStruct) {
          value = jsonify(value);
        }
        output[key] = value;
      }
    }
    // print prototype members, ignore the root object members
    if (struct.prototype != null &&
        struct.prototype!.id != HTLexicon.prototype) {
      final inherits = jsonify(struct.prototype!);
      output.addAll(inherits);
    }
    return output;
  }

  static dynamic _toJsonValue(dynamic value, HTNamespace closure) {
    if (value is Iterable) {
      final list = [];
      for (final item in value) {
        final result = _toJsonValue(item, closure);
        list.add(result);
      }
      return list;
    } else if (value is Map) {
      final struct = HTStruct(closure);
      for (final key in value.keys) {
        final fieldKey = key.toString();
        final fieldValue = _toJsonValue(value[key], closure);
        struct.define(fieldKey, fieldValue);
      }
      return struct;
    } else {
      return value;
    }
  }

  static HTStruct fromJson(Map<String, dynamic> jsonData, HTNamespace closure) {
    final struct = HTStruct(closure);
    for (final key in jsonData.keys) {
      var value = _toJsonValue(jsonData[key], closure);
      struct.define(key, value);
    }
    return struct;
  }

  String? id;

  HTStruct? prototype;

  final fields = <String, dynamic>{};

  HTNamespace namespace;

  HTStruct(HTNamespace closure,
      {this.id, this.prototype, Map<String, dynamic>? fields})
      : namespace = HTNamespace(id: id ?? HTLexicon.STRUCT, closure: closure) {
    namespace.define(HTLexicon.THIS, HTConst(HTLexicon.THIS, value: this));
    if (fields != null) {
      this.fields.addAll(fields);
    }
  }

  Map<String, dynamic> toJson() => jsonify(this);

  @override
  String toString() {
    final content = stringify(this, from: this);
    return '{\n$content}';
  }

  /// Check if this struct has the key in its own fields
  bool own(String varName) {
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

  @override
  dynamic memberGet(String varName) {
    dynamic value;
    if (varName == SemanticNames.prototype) {
      return prototype;
    }
    if (fields.containsKey(varName)) {
      value = fields[varName];
    } else if (prototype != null) {
      value = prototype!.memberGet(varName);
    }
    if (value is HTFunction) {
      value.namespace = namespace;
      value.instance = this;
    }
    return value;
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    if (varName == SemanticNames.prototype) {
      prototype = namespace.closure!.memberGet(varName);
      return;
    }
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
}
