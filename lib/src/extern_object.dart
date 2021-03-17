import 'errors.dart';
import 'object.dart';
import 'type.dart';
import 'lexicon.dart';

abstract class HTExternObject<T> extends HTObject {
  T externObject;
  HTExternObject(this.externObject);
}

/// Mirror object for dart number.
class HTNumber extends HTExternObject<num> {
  HTNumber(num value) : super(value);

  @override
  final typeid = HTTypeId.number;

  @override
  dynamic fetch(String id, {String from = HTLexicon.global}) {
    switch (id) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.toString();
      case 'toStringAsFixed':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.toStringAsFixed(positionalArgs.first);
      case 'truncate':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.truncate();
      default:
        throw HTErrorUndefined(id);
    }
  }
}

/// Mirror object for dart boolean.
class HTBoolean extends HTExternObject<bool> {
  HTBoolean(bool value) : super(value);

  @override
  final typeid = HTTypeId.boolean;

  @override
  dynamic fetch(String id, {String from = HTLexicon.global}) {
    switch (id) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.toString();
      case 'parse':
        return externObject.toString;
      default:
        throw HTErrorUndefined(id);
    }
  }
}

/// Mirror object for dart string.
class HTString extends HTExternObject<String> {
  HTString(String value) : super(value);

  @override
  final typeid = HTTypeId.string;

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'subString':
        return externObject.substring;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

/// Mirror object for dart list.
class HTList<T> extends HTExternObject<List<T>> {
  final HTTypeId valueType;

  HTList(List<T> value, {this.valueType = HTTypeId.ANY}) : super(value);

  @override
  final typeid = HTTypeId.list;

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.toString();
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'contains':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.contains(positionalArgs.first);
      case 'add':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.add(positionalArgs.first);
      case 'addAll':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.clear();
      case 'removeAt':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.removeAt(positionalArgs.first);
      case 'indexOf':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.indexOf(positionalArgs.first);
      case 'elementAt':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.elementAt(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

/// Mirror object for dart map.
class HTMap<K, V> extends HTExternObject<Map<K, V>> {
  final HTTypeId keyType;
  final HTTypeId valueType;

  HTMap(Map<K, V> value, {this.keyType = HTTypeId.ANY, this.valueType = HTTypeId.ANY}) : super(value);

  @override
  final typeid = HTTypeId.map;

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.toString();
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
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.containsKey(positionalArgs.first);
      case 'containsValue':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.containsValue(positionalArgs.first);
      case 'addAll':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.addAll(positionalArgs.first);
      case 'clear':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => externObject.clear();
      case 'remove':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) =>
            externObject.remove(positionalArgs.first);
      default:
        throw HTErrorUndefined(varName);
    }
  }
}
