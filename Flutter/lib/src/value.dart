import 'package:hetu_script_flutter/hetu.dart';
import 'package:hetu_script_flutter/src/buildin.dart';

import 'common.dart';

class HS_Type {
  // List<HS_Type> get inheritances;
  // List<HS_Type> get compositions;
  final String name;
  final List<HS_Type> arguments = [];

  HS_Type({this.name = HS_Common.ANY, List<HS_Type> arguments}) {
    if (arguments != null) this.arguments.addAll(arguments);
  }

  static final NULL = HS_Type(name: HS_Common.NULL);
  static final VOID = HS_Type(name: HS_Common.VOID);
  static final CLASS = HS_Type(name: HS_Common.CLASS);
  static final NAMESPACE = HS_Type(name: HS_Common.NAMESPACE);
  static final unknown = HS_Type(name: HS_Common.unknown);
  static final number = HS_Type(name: HS_Common.number);
  static final boolean = HS_Type(name: HS_Common.boolean);
  static final string = HS_Type(name: HS_Common.string);
  static final list = HS_Type(name: HS_Common.list);
  static final map = HS_Type(name: HS_Common.map);

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

  bool isA(HS_Type typeid) {
    bool result = false;
    if ((typeid.name == HS_Common.ANY) || (this.name == HS_Common.NULL)) {
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

  bool isNotA(HS_Type typeid) => !isA(typeid);
}

HS_Type HS_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return HS_Type.NULL;
  } else if (value is HS_Class) {
    return HS_Type.CLASS;
  } else if (value is HS_Instance) {
    return value.typeid;
  } else if (value is HS_Function) {
    return value.typeid;
  } else if (value is num) {
    return HS_Type.number;
  } else if (value is bool) {
    return HS_Type.boolean;
  } else if (value is String) {
    return HS_Type.string;
  } else if (value is List) {
    // var list_darttype = value.runtimeType.toString();
    // var item_darttype = list_darttype.substring(list_darttype.indexOf('<') + 1, list_darttype.indexOf('>'));
    // if ((item_darttype != 'dynamic') && (value.isNotEmpty)) {
    //   valType = HS_TypeOf(value.first);
    // }
    HS_Type valType = HS_Type();
    if (value.isNotEmpty) {
      valType = HS_TypeOf(value.first);
      for (var item in value) {
        if (HS_TypeOf(item) != valType) {
          valType = HS_Type();
          break;
        }
      }
    }

    return HS_Type(name: HS_Common.list, arguments: [valType]);
  } else if (value is Map) {
    HS_Type keyType = HS_Type();
    HS_Type valType = HS_Type();
    if (value.keys.isNotEmpty) {
      keyType = HS_TypeOf(value.keys.first);
      for (var key in value.keys) {
        if (HS_TypeOf(key) != keyType) {
          keyType = HS_Type();
          break;
        }
      }
    }
    if (value.values.isNotEmpty) {
      valType = HS_TypeOf(value.values.first);
      for (var value in value.values) {
        if (HS_TypeOf(value) != valType) {
          valType = HS_Type();
          break;
        }
      }
    }
    return HS_Type(name: HS_Common.map, arguments: [keyType, valType]);
  } else {
    return HS_Type.unknown;
  }
}

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  final String name;
  bool used = false;

  HS_Value({this.name});
}

class Declaration {
  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HS_Value
  dynamic value;

  final HS_Type typeid;
  final bool nullable;
  final bool mutable;

  Declaration(this.typeid, {this.value, this.nullable = false, this.mutable = true});
}
