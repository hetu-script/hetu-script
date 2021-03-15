import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'extern_class.dart' show HT_ExternNamespace;

abstract class HT_ExternObject<T> extends HT_ExternNamespace with HT_Type {
  T externObject;
  HT_ExternObject(this.externObject);
}

/// Mirror object for dart number.
class HT_Dart_Number extends HT_ExternObject<num> {
  HT_Dart_Number(num value) : super(value);

  @override
  final typeid = HT_TypeId.number;

  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'toStringAsFixed':
        return externObject.toStringAsFixed;
      case 'truncate':
        return externObject.truncate;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Mirror object for dart boolean.
class HT_DartObject_Boolean extends HT_ExternObject<bool> {
  HT_DartObject_Boolean(bool value) : super(value);

  @override
  final typeid = HT_TypeId.boolean;

  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'parse':
        return externObject.toString;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Mirror object for dart string.
class HT_DartObject_String extends HT_ExternObject<String> {
  HT_DartObject_String(String value) : super(value);

  @override
  final typeid = HT_TypeId.string;

  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'isEmpty':
        return externObject.isEmpty;
      case 'subString':
        return externObject.substring;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Mirror object for dart list.
class HT_DartObject_List<T> extends HT_ExternObject<List<T>> {
  final String valueType;

  HT_DartObject_List(List<T> value, {this.valueType = HT_Lexicon.ANY}) : super(value);

  @override
  final typeid = HT_TypeId.list;

  @override
  dynamic fetch(String id) {
    switch (id) {
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
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}

/// Mirror object for dart map.
class HT_DartObject_Map<K, V> extends HT_ExternObject<Map<K, V>> {
  final String keyType;
  final String valueType;

  HT_DartObject_Map(Map<K, V> value, {this.keyType = HT_Lexicon.ANY, this.valueType = HT_Lexicon.ANY}) : super(value);

  @override
  final typeid = HT_TypeId.map;

  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'length':
        return externObject.length;
      case 'isEmpty':
        return externObject.isEmpty;
      case 'isNotEmpty':
        return externObject.isNotEmpty;
      case 'keys':
        return externObject.keys;
      case 'values':
        return externObject.values;
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
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    throw HTErr_Assign(id);
  }
}
