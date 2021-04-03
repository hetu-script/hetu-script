import 'errors.dart';
import 'object.dart';
import 'type.dart';
import 'lexicon.dart';

class HTExternObject<T> with HTObject {
  @override
  final typeid;

  T externObject;
  HTExternObject(this.externObject, {this.typeid = HTTypeId.unknown});
}

/// Mirror object for dart number.
class HTNumber extends HTExternObject<num> {
  HTNumber(num value) : super(value, typeid: HTTypeId.number);

  @override
  dynamic memberGet(String id, {String from = HTLexicon.global}) {
    switch (id) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.toString();
      case 'toStringAsFixed':
        return (
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTTypeId> typeArgs = const []}) {
          final digit = positionalArgs.first;
          return externObject.toStringAsFixed(digit);
        };
      case 'truncate':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.truncate();
      default:
        throw HTErrorUndefined(id);
    }
  }
}

/// Mirror object for dart boolean.
class HTBoolean extends HTExternObject<bool> {
  HTBoolean(bool value) : super(value, typeid: HTTypeId.boolean);

  @override
  dynamic memberGet(String id, {String from = HTLexicon.global}) {
    switch (id) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.toString();
      case 'parse':
        return externObject.toString;
      default:
        throw HTErrorUndefined(id);
    }
  }
}

/// Mirror object for dart string.
class HTString extends HTExternObject<String> {
  HTString(String value) : super(value, typeid: HTTypeId.string);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.toString();
      case 'isEmpty':
        return externObject.isEmpty;
      case 'subString':
        return externObject.substring;
      case 'startsWith':
        return externObject.startsWith;
      case 'endsWith':
        return externObject.endsWith;
      case 'indexOf':
        return externObject.indexOf;
      case 'lastIndexOf':
        return externObject.lastIndexOf;
      case 'compareTo':
        return externObject.compareTo;
      case 'trim':
        return externObject.trim;
      case 'trimLeft':
        return externObject.trimLeft;
      case 'trimRight':
        return externObject.trimRight;
      case 'padLeft':
        return externObject.padLeft;
      case 'padRight':
        return externObject.padRight;
      case 'contains':
        return externObject.contains;
      case 'replaceFirst':
        return externObject.replaceFirst;
      case 'replaceAll':
        return externObject.replaceAll;
      case 'replaceRange':
        return externObject.replaceRange;
      case 'split':
        return externObject.split;
      case 'toLowerCase':
        return externObject.toLowerCase;
      case 'toUpperCase':
        return externObject.toUpperCase;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

/// Mirror object for dart list.
class HTList extends HTExternObject<List> {
  HTList(List value, {HTTypeId valueType = HTTypeId.ANY})
      : super(value, typeid: HTTypeId(HTLexicon.list, arguments: [valueType]));

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.toString();
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'first':
        return externObject.first;
      case 'last':
        return externObject.last;
      case 'contains':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.contains(positionalArgs.first);
      case 'add':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.add(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.clear();
      case 'removeAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.removeAt(positionalArgs.first);
      case 'indexOf':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.indexOf(positionalArgs.first);
      case 'elementAt':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.elementAt(positionalArgs.first);
      case 'join':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.join(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

/// Mirror object for dart map.
class HTMap extends HTExternObject<Map> {
  HTMap(Map value, {HTTypeId keyType = HTTypeId.ANY, HTTypeId valueType = HTTypeId.ANY})
      : super(value, typeid: HTTypeId(HTLexicon.list, arguments: [keyType, valueType]));

  @override
  final typeid = HTTypeId.map;

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.toString();
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'keys':
        return externObject.keys.toList();
      case 'values':
        return externObject.values.toList();
      case 'containsKey':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.containsKey(positionalArgs.first);
      case 'containsValue':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.containsValue(positionalArgs.first);
      case 'addAll':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.clear();
      case 'remove':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            externObject.remove(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}
