import '../grammar/lexicon.dart';
import '../value/struct/struct.dart';

var _curIndentCount = 0;

String _curIndent() {
  final output = StringBuffer();
  var i = _curIndentCount;
  while (i > 0) {
    output.write(HTLexicon.indentSpaces);
    --i;
  }
  return output.toString();
}

String stringify(dynamic object) {
  final output = StringBuffer();
  if (object is String) {
    if (object.contains("'")) {
      final objString = object.replaceAll(r"'", r"\'");
      output.write("'$objString'");
    } else {
      output.write("'$object'");
    }
  } else if (object is HTStruct) {
    if (object.fields.isEmpty) {
      output.write('${HTLexicon.bracesLeft}${HTLexicon.bracesRight}');
    } else {
      output.writeln(HTLexicon.bracesLeft);
      final structString = stringifyStructMembers(object);
      output.write(structString);
      output.write(HTLexicon.bracesRight);
    }
  } else if (object is List) {
    final listString = stringifyList(object);
    output.write(listString);
  } else if (object is Map) {
    output.write(HTLexicon.bracesLeft);
    final keys = object.keys.toList();
    for (var i = 0; i < keys.length; ++i) {
      final key = keys[i];
      final value = object[key];
      final keyString = stringify(key);
      final valueString = stringify(value);
      output.write('$keyString: $valueString');
      if (i < keys.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.bracesRight);
  } else {
    output.write(object.toString());
  }
  return output.toString();
}

String stringifyList(List list) {
  if (list.isEmpty) {
    return '${HTLexicon.bracketsLeft}${HTLexicon.bracketsRight}';
  }
  final output = StringBuffer();
  output.writeln(HTLexicon.bracketsLeft);
  ++_curIndentCount;
  for (var i = 0; i < list.length; ++i) {
    final item = list[i];
    output.write(_curIndent());
    final itemString = stringify(item);
    output.write(itemString);
    if (i < list.length - 1) {
      output.write(HTLexicon.comma);
    }
    output.writeln();
  }
  --_curIndentCount;
  output.write(HTLexicon.bracketsRight);
  return output.toString();
}

/// Print all members of a struct object to a string.
String stringifyStructMembers(HTStruct struct, {HTStruct? from}) {
  final output = StringBuffer();
  ++_curIndentCount;
  for (var i = 0; i < struct.fields.length; ++i) {
    final key = struct.fields.keys.elementAt(i);
    if (key.startsWith(HTLexicon.internalMarker)) {
      continue;
    }
    if (from != null && from != struct) {
      if (from.contains(key)) {
        continue;
      }
    }
    output.write(_curIndent());
    final value = struct.fields[key];
    final valueBuffer = StringBuffer();
    if (value is HTStruct) {
      final content = stringifyStructMembers(value, from: from);
      valueBuffer.writeln(HTLexicon.bracesLeft);
      valueBuffer.write(content);
      valueBuffer.write(_curIndent());
      valueBuffer.write(HTLexicon.bracesRight);
    } else {
      final valueString = stringify(value);
      valueBuffer.write(valueString);
    }
    output.write('$key${HTLexicon.colon} $valueBuffer');
    if (i < struct.fields.length - 1) {
      output.write(HTLexicon.comma);
    }
    output.writeln();
  }
  if (struct.prototype != null && struct.prototype!.id != HTLexicon.prototype) {
    final inherits = stringifyStructMembers(struct.prototype!, from: struct);
    output.write(inherits);
  }
  --_curIndentCount;
  return output.toString();
}
