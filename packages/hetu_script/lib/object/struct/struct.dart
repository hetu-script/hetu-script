import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../object.dart';
import '../../type/type.dart';
import '../function/function.dart';

/// A prototype based dynamic object.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTObject {
  static String stringify(HTObject object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTStruct)._toString();
  }

  String? id;

  HTStruct? prototype;

  final fields = <String, dynamic>{};

  HTStruct({this.id, this.prototype, Map<String, dynamic>? fields}) {
    if (fields != null) {
      this.fields.addAll(fields);
    }
    this.fields[SemanticNames.prototype] = prototype;
  }

  String _toString() {
    if (id != null) {
      return id!;
    } else {
      final output = StringBuffer();
      output.writeln(HTLexicon.curlyLeft);
      for (var i = 0; i < fields.length; ++i) {
        final key = fields.keys.elementAt(i);
        if (!key.startsWith(SemanticNames.internalMarker)) {
          output.write(HTLexicon.indentSpaces);
          final valueString = fields[key].toString();
          output.write('$key${HTLexicon.colon} $valueString');
          if (i < fields.length - 1) {
            output.write(HTLexicon.comma);
          }
          output.writeln();
        }
      }
      output.write(HTLexicon.curlyRight);
      return output.toString();
    }
  }

  @override
  String toString() {
    final func = memberGet('toString');
    if (func is HTFunction) {
      return func.call();
    } else if (func is Function) {
      return func();
    } else {
      return _toString();
    }
  }

  @override
  bool contains(String varName, {bool recursive = true}) {
    if (fields.containsKey(varName)) {
      return true;
    } else if (recursive && prototype != null && prototype!.contains(varName)) {
      return true;
    }
    return false;
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
    if (fields.containsKey(varName)) {
      return fields[varName];
    }
    if (prototype != null) {
      return prototype!.memberGet(varName);
    }
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
