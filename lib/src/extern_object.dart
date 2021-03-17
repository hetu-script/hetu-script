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
        return externObject.toString;
      case 'toStringAsFixed':
        return externObject.toStringAsFixed;
      case 'truncate':
        return externObject.truncate;
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
        return externObject.toString;
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
        return externObject.toString;
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'add':
        return externObject.add;
      case 'addAll':
        return externObject.addAll;
      case 'clear':
        return externObject.clear;
      case 'removeAt':
        return externObject.removeAt;
      case 'indexOf':
        return externObject.indexOf;
      case 'elementAt':
        return externObject.elementAt;
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
        return externObject.toString;
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
        return externObject.containsKey;
      case 'containsValue':
        return externObject.containsValue;
      // TODO: subGet/Set、memberGet/Set和call本质都应该是函数（__sub__get__, __sub__set__）
      case '__sub__get__':
        return;
      case '__sub__set__':
        return;
      case 'addAll':
        return externObject.addAll;
      case 'clear':
        return externObject.clear;
      case 'remove':
        return externObject.remove;
      case 'putIfAbsent':
        return externObject.putIfAbsent;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}
