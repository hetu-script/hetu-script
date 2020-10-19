import 'package:hetu_script/hetu.dart';

import 'environment.dart';

class HT_Type {
  // List<HT_Type> get inheritances;
  // List<HT_Type> get compositions;
  String name;
  List<HT_Type> arguments = [];

  HT_Type({this.name, List<HT_Type> arguments}) {
    name ??= env.lexicon.ANY;
    if (arguments != null) this.arguments.addAll(arguments);
  }

  static final NULL = HT_Type(name: env.lexicon.NULL);
  static final VOID = HT_Type(name: env.lexicon.VOID);
  static final CLASS = HT_Type(name: env.lexicon.CLASS);
  static final NAMESPACE = HT_Type(name: env.lexicon.NAMESPACE);
  static final unknown = HT_Type(name: env.lexicon.unknown);
  static final number = HT_Type(name: env.lexicon.number);
  static final boolean = HT_Type(name: env.lexicon.boolean);
  static final string = HT_Type(name: env.lexicon.string);
  static final list = HT_Type(name: env.lexicon.list);
  static final map = HT_Type(name: env.lexicon.map);

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(name);
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

  bool isA(HT_Type typeid) {
    bool result = false;
    if ((typeid.name == env.lexicon.ANY) || (this.name == env.lexicon.NULL)) {
      result = true;
    } else {
      if (this.name == typeid.name) {
        if (this.arguments.length >= typeid.arguments.length) {
          result = true;
          for (var i = 0; i < typeid.arguments.length; ++i) {
            if (this.arguments[i].isNotA(typeid.arguments[i])) {
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

  bool isNotA(HT_Type typeid) => !isA(typeid);
}

HT_Type HT_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return HT_Type.NULL;
  } else if (value is HT_Class) {
    return HT_Type.CLASS;
  } else if (value is HT_Instance) {
    return value.typeid;
  } else if (value is HT_Function) {
    return value.typeid;
  } else if (value is num) {
    return HT_Type.number;
  } else if (value is bool) {
    return HT_Type.boolean;
  } else if (value is String) {
    return HT_Type.string;
  } else if (value is List) {
    // var list_darttype = value.runtimeType.toString();
    // var item_darttype = list_darttype.substring(list_darttype.indexOf('<') + 1, list_darttype.indexOf('>'));
    // if ((item_darttype != 'dynamic') && (value.isNotEmpty)) {
    //   valType = HT_TypeOf(value.first);
    // }
    HT_Type valType = HT_Type();
    if (value.isNotEmpty) {
      valType = HT_TypeOf(value.first);
      for (var item in value) {
        if (HT_TypeOf(item) != valType) {
          valType = HT_Type();
          break;
        }
      }
    }

    return HT_Type(name: env.lexicon.list, arguments: [valType]);
  } else if (value is Map) {
    HT_Type keyType = HT_Type();
    HT_Type valType = HT_Type();
    if (value.keys.isNotEmpty) {
      keyType = HT_TypeOf(value.keys.first);
      for (var key in value.keys) {
        if (HT_TypeOf(key) != keyType) {
          keyType = HT_Type();
          break;
        }
      }
    }
    if (value.values.isNotEmpty) {
      valType = HT_TypeOf(value.values.first);
      for (var value in value.values) {
        if (HT_TypeOf(value) != valType) {
          valType = HT_Type();
          break;
        }
      }
    }
    return HT_Type(name: env.lexicon.map, arguments: [keyType, valType]);
  } else {
    return HT_Type.unknown;
  }
}

/// Value是命名空间、类和实例的基类
abstract class HT_Value {
  final String name;
  bool used = false;

  HT_Value({this.name});
}

class Declaration {
  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HT_Value
  dynamic value;

  final HT_Type typeid;
  final bool nullable;
  final bool mutable;

  Declaration(this.typeid, {this.value, this.nullable = false, this.mutable = true});
}
