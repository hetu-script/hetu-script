import 'package:hetu_script/hetu.dart';
import 'package:hetu_script/src/buildin.dart';

import 'common.dart';

class HS_Type {
  // List<HS_Type> get inheritances;
  // List<HS_Type> get compositions;

  static var any = HS_Type()..name = HS_Common.ANY;
  static var number = HS_Type()..name = HS_Common.number;
  static var boolean = HS_Type()..name = HS_Common.boolean;
  static var string = HS_Type()..name = HS_Common.string;
  static var list = HS_Type()..name = HS_Common.list;
  static var map = HS_Type()..name = HS_Common.map;
}

HS_Type HS_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return null;
  } else if (value is HS_Instance) {
    return value;
  } else if (value is num) {
    return HS_Type.number;
  } else if (value is bool) {
    return HS_Type.boolean;
  } else if (value is String) {
    return HS_Type.string;
  } else if (value is List) {
    var valType = HS_TypeOf(value.first);
    for (var value in value) {
      if (HS_TypeOf(value) != valType) {
        valType = HS_Type.any;
        break;
      }
    }
    return HS_Type()
      ..name = HS_Common.list
      ..typeArgs = [valType];
  } else if (value is Map) {
    var keyType = HS_TypeOf(value.keys.first);
    for (var key in value.keys) {
      if (HS_TypeOf(key) != keyType) {
        keyType = HS_Type.any;
        break;
      }
    }
    var valType = HS_TypeOf(value.values.first);
    for (var value in value.values) {
      if (HS_TypeOf(value) != valType) {
        valType = HS_Type.any;
        break;
      }
    }
    return HS_Type()
      ..name = HS_Common.map
      ..typeArgs = [keyType, valType];
  } else {
    return HS_Type()..name = value.toString();
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

  final HS_Type type;
  final bool nullable;
  final bool mutable;

  Declaration(this.type, {this.value, this.nullable = false, this.mutable = true});
}
