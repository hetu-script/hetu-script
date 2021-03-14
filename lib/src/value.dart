import 'lexicon.dart';
import 'function.dart';

mixin HT_Type {
  HT_TypeId get typeid;
}

class HT_TypeId {
  // List<HT_Type> get inheritances;
  // List<HT_Type> get compositions;
  final String id;
  final List<HT_TypeId> arguments;

  const HT_TypeId(this.id, {this.arguments = const []});

  static const ANY = HT_TypeId(HT_Lexicon.ANY);
  static const NULL = HT_TypeId(HT_Lexicon.NULL);
  static const VOID = HT_TypeId(HT_Lexicon.VOID);
  static const CLASS = HT_TypeId(HT_Lexicon.CLASS);
  static const namespace = HT_TypeId(HT_Lexicon.NAMESPACE);
  static const function = HT_TypeId(HT_Lexicon.function);
  static const unknown = HT_TypeId(HT_Lexicon.unknown);
  static const number = HT_TypeId(HT_Lexicon.number);
  static const boolean = HT_TypeId(HT_Lexicon.boolean);
  static const string = HT_TypeId(HT_Lexicon.string);
  static const list = HT_TypeId(HT_Lexicon.list);
  static const map = HT_TypeId(HT_Lexicon.map);

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(id);
    if (arguments.isNotEmpty) {
      typename.write('<');
      for (var i = 0; i < arguments.length; ++i) {
        typename.write(arguments[i]);
        if ((arguments.length > 1) && (i != arguments.length - 1)) typename.write(', ');
      }
      typename.write('>');
    }
    return typename.toString();
  }

  bool isA(HT_TypeId typeid) {
    var result = false;
    if ((typeid.id == HT_Lexicon.ANY) || (id == HT_Lexicon.NULL)) {
      result = true;
    } else {
      if (id == typeid.id) {
        if (arguments.length >= typeid.arguments.length) {
          result = true;
          for (var i = 0; i < typeid.arguments.length; ++i) {
            if (arguments[i].isNotA(typeid.arguments[i])) {
              result = false;
              break;
            }
          }
        } else {
          result = false;
        }
      }
    }
    return result;
  }

  bool isNotA(HT_TypeId typeid) => !isA(typeid);
}

HT_TypeId HT_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return HT_TypeId.NULL;
  } // Class, Object, external class
  else if (value is HT_Type) {
    return value.typeid;
  } else if (value is num) {
    return HT_TypeId.number;
  } else if (value is bool) {
    return HT_TypeId.boolean;
  } else if (value is String) {
    return HT_TypeId.string;
  } else if (value is List) {
    // var list_darttype = value.runtimeType.toString();
    // var item_darttype = list_darttype.substring(list_darttype.indexOf('<') + 1, list_darttype.indexOf('>'));
    // if ((item_darttype != 'dynamic') && (value.isNotEmpty)) {
    //   valType = HT_TypeOf(value.first);
    // }
    var valType = HT_TypeId.ANY;
    if (value.isNotEmpty) {
      valType = HT_TypeOf(value.first);
      for (final item in value) {
        if (HT_TypeOf(item) != valType) {
          valType = HT_TypeId.ANY;
          break;
        }
      }
    }

    return HT_TypeId(HT_Lexicon.list, arguments: [valType]);
  } else if (value is Map) {
    var keyType = HT_TypeId.ANY;
    var valType = HT_TypeId.ANY;
    if (value.keys.isNotEmpty) {
      keyType = HT_TypeOf(value.keys.first);
      for (final key in value.keys) {
        if (HT_TypeOf(key) != keyType) {
          keyType = HT_TypeId.ANY;
          break;
        }
      }
    }
    if (value.values.isNotEmpty) {
      valType = HT_TypeOf(value.values.first);
      for (final value in value.values) {
        if (HT_TypeOf(value) != valType) {
          valType = HT_TypeId.ANY;
          break;
        }
      }
    }
    return HT_TypeId(HT_Lexicon.map, arguments: [keyType, valType]);
  } else {
    return HT_TypeId.unknown;
  }
}

class _HT_Null with HT_Type {
  const _HT_Null();

  @override
  HT_TypeId get typeid => HT_TypeId.NULL;
}

/// Value是命名空间、类和实例的基类
abstract class HT_Value {
  static const NULL = _HT_Null();

  final String id;
  //bool used = false;

  HT_Value(this.id);
}

class HT_Declaration {
  final String id;

  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HT_Value
  dynamic value;
  HT_Function? getter;
  HT_Function? setter;

  final HT_TypeId declType;
  final bool isExtern;
  final bool isNullable;
  final bool isImmutable;

  HT_Declaration(this.id,
      {this.value,
      this.getter,
      this.setter,
      this.declType = HT_TypeId.ANY,
      this.isExtern = false,
      this.isNullable = false,
      this.isImmutable = false});
}
