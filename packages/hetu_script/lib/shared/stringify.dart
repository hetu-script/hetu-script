import '../grammar/lexicon.dart';

String stringify(Object object) {
  final output = StringBuffer();
  if (object is String) {
    if (object.contains("'")) {
      final objString = object.replaceAll(r"'", r"\'");
      output.write("'$objString'");
    } else {
      output.write("'$object'");
    }
  } else if (object is List) {
    output.write(HTLexicon.squareLeft);
    for (var i = 0; i < object.length; ++i) {
      final item = object[i];
      final itemString = stringify(item);
      output.write(itemString);
      if (i < object.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.squareRight);
  } else if (object is Map) {
    output.write(HTLexicon.curlyLeft);
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
    output.write(HTLexicon.curlyRight);
  } else {
    output.write(object.toString());
  }
  return output.toString();
}
