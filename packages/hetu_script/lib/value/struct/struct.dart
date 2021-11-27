import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../entity.dart';
import '../function/function.dart';
import '../../declaration/namespace/namespace.dart';
import '../../value/const.dart';

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

  static Map<String, dynamic> jsonify(HTStruct struct) {
    final output = <String, dynamic>{};
    for (final key in struct.fields.keys) {
      if (!key.startsWith(SemanticNames.internalMarker)) {
        var value = struct.fields[key];
        if (value is HTStruct) {
          value = jsonify(value);
        }
        output[key] = value;
      }
    }
    if (struct.prototype != null &&
        struct.prototype!.id != HTLexicon.prototype) {
      final inherits = jsonify(struct.prototype!);
      output.addAll(inherits);
    }
    return output;
  }

  /// Print all members of a struct object.
  static String stringify(HTStruct struct, {HTStruct? from}) {
    final output = StringBuffer();
    // output.writeln(HTLexicon.curlyLeft);
    ++_curIndentCount;
    for (var i = 0; i < struct.fields.length; ++i) {
      final key = struct.fields.keys.elementAt(i);
      if (from != null && from != struct) {
        if (from.contains(key)) {
          continue;
        }
      }
      if (!key.startsWith(SemanticNames.internalMarker)) {
        output.write(_curIndent());
        final value = struct.fields[key];
        final valueString = StringBuffer();
        if (value is HTStruct) {
          final content = stringify(value, from: from);
          valueString.writeln(HTLexicon.curlyLeft);
          valueString.write(content);
          valueString.write(_curIndent());
          valueString.write(HTLexicon.curlyRight);
        } else {
          valueString.write(value);
        }
        output.write('$key${HTLexicon.colon} $valueString');
        if (i < struct.fields.length - 1) {
          output.write(HTLexicon.comma);
        }
        output.writeln();
      }
    }
    --_curIndentCount;
    if (struct.prototype != null &&
        struct.prototype!.id != HTLexicon.prototype) {
      final inherits = stringify(struct.prototype!);
      output.write(inherits);
    }
    // output.write(_curIndent());
    // output.write(HTLexicon.curlyRight);
    return output.toString();
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
    this.fields[SemanticNames.prototype] = prototype;
  }

  @override
  String toString() => stringify(this, from: this);

  @override
  bool contains(String varName, {bool recursive = true}) {
    if (fields.containsKey(varName)) {
      return true;
    } else if (recursive && prototype != null && prototype!.contains(varName)) {
      return true;
    }
    return false;
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
    fields.remove(id);
  }

  @override
  dynamic memberGet(String varName) {
    dynamic value;
    if (fields.containsKey(varName)) {
      value = fields[varName];
    } else if (prototype != null) {
      value = prototype!.memberGet(varName);
    }
    if (value is HTFunction) {
      value.namespace = namespace;
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
  dynamic subGet(dynamic varName) {
    return memberGet(varName.toString());
  }

  @override
  void subSet(dynamic varName, dynamic varValue) {
    memberSet(varName.toString(), varValue);
  }
}
