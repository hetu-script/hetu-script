import '../lexicon/lexicon.dart';
import '../value/struct/struct.dart';

var _curIndentCount = 0;

const kIndent = '  ';

String _curIndent([String indent = kIndent]) {
  final output = StringBuffer();
  var i = _curIndentCount;
  while (i > 0) {
    output.write(indent);
    --i;
  }
  return output.toString();
}

String stringify(dynamic object,
    {String indent = kIndent, bool asStringLiteral = false}) {
  final output = StringBuffer();
  if (object is String) {
    if (asStringLiteral) {
      // if (object.contains("'")) {
      //   final objString = object.replaceAll(r"'", r"\'");
      //   return "'$objString'";
      // } else {
      return "'$object'";
      // }
    } else {
      return object;
    }
  } else if (object is HTStruct) {
    if (object.isEmpty) {
      output.write(
          '${HTLexicon.functionBlockStart}${HTLexicon.functionBlockEnd}');
    } else {
      output.writeln(HTLexicon.functionBlockStart);
      final structString = stringifyStructMembers(object, indent: indent);
      output.write(structString);
      output.write(_curIndent(indent));
      output.write(HTLexicon.functionBlockEnd);
    }
  } else if (object is Iterable) {
    final listString = stringifyList(object, indent: indent);
    output.write(listString);
  } else if (object is Map) {
    output.write(HTLexicon.functionBlockStart);
    final keys = object.keys.toList();
    for (var i = 0; i < keys.length; ++i) {
      final key = keys[i];
      final value = object[key];
      final keyString = stringify(key, indent: indent);
      final valueString = stringify(value, indent: indent);
      output.write('$keyString: $valueString');
      if (i < keys.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.functionBlockEnd);
  } else {
    output.write(object.toString());
  }
  return output.toString();
}

String stringifyList(Iterable list, {String indent = kIndent}) {
  if (list.isEmpty) {
    return '${HTLexicon.listStart}${HTLexicon.listEnd}';
  }
  final output = StringBuffer();
  output.writeln(HTLexicon.listStart);
  ++_curIndentCount;
  for (var i = 0; i < list.length; ++i) {
    final item = list.elementAt(i);
    output.write(_curIndent(indent));
    final itemString = stringify(item, indent: indent, asStringLiteral: true);
    output.write(itemString);
    if (i < list.length - 1) {
      output.write(HTLexicon.comma);
    }
    output.writeln();
  }
  --_curIndentCount;
  output.write(_curIndent(indent));
  output.write(HTLexicon.listEnd);
  return output.toString();
}

/// Print all members of a struct object to a string.
String stringifyStructMembers(HTStruct struct,
    {String indent = kIndent, HTStruct? from}) {
  final output = StringBuffer();
  ++_curIndentCount;
  for (var i = 0; i < struct.length; ++i) {
    final key = struct.keys.elementAt(i);
    if (key.startsWith(HTLexicon.internalPrefix)) {
      continue;
    }
    if (from != null && from != struct) {
      if (from.contains(key)) {
        continue;
      }
    }
    output.write(_curIndent(indent));
    final value = struct[key];
    final valueBuffer = StringBuffer();
    if (value is HTStruct) {
      if (value.isEmpty) {
        valueBuffer.write(
            '${HTLexicon.functionBlockStart}${HTLexicon.functionBlockEnd}');
      } else {
        final content =
            stringifyStructMembers(value, indent: indent, from: from);
        valueBuffer.writeln(HTLexicon.functionBlockStart);
        valueBuffer.write(content);
        valueBuffer.write(_curIndent(indent));
        valueBuffer.write(HTLexicon.functionBlockEnd);
      }
    } else {
      final valueString =
          stringify(value, indent: indent, asStringLiteral: true);
      valueBuffer.write(valueString);
    }
    output.write('$key${HTLexicon.structValueIndicator} $valueBuffer');
    if (i < struct.length - 1) {
      output.write(HTLexicon.comma);
    }
    output.writeln();
  }
  if (struct.prototype != null &&
      struct.prototype!.id != HTLexicon.globalPrototypeId) {
    final inherits =
        stringifyStructMembers(struct.prototype!, indent: indent, from: struct);
    output.write(inherits);
  }
  --_curIndentCount;
  return output.toString();
}
