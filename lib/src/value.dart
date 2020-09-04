import 'common.dart';
import 'class.dart';

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  String get type;
  // TODO：判断变量是否用过，用于死代码警告
  bool used = false;
  HS_Value();
}

class HS_Type {
  final String name;
  final List<String> typeParams = [];

  @override
  String toString() {
    if (typeParams.isEmpty) {
      return name;
    } else {
      var fullname = '$name<';
      for (var param in typeParams) {
        fullname += param;
      }
      fullname += '>';
      return fullname;
    }
  }

  HS_Type(this.name, {List<String> typeParams}) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }

  operator ==(dynamic other) {
    if (other is HS_Type) {
      return true;
    }
    return false;
  }
}

String HS_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return HS_Common.Null;
  } else if (value is HS_Value) {
    return value.type;
  } else if (value is num) {
    return HS_Common.Number;
  } else if (value is bool) {
    return HS_Common.Boolean;
  } else if (value is String) {
    return HS_Common.Str;
  } else if (value is List) {
    return HS_Common.List;
  } else if (value is Map) {
    return HS_Common.Map;
  } else {
    return value.runtimeType.toString();
  }
}

List<String> HS_TypeParamsOf(dynamic value) {
  if (value is List) {
    String valType = HS_TypeOf(value.first);
    for (var value in value) {
      if (HS_TypeOf(value) != valType) {
        valType = HS_Common.Any;
        break;
      }
    }
    return [valType];
  } else if (value is Map) {
    String keyType = HS_TypeOf(value.keys.first);
    for (var key in value.keys) {
      if (HS_TypeOf(key) != keyType) {
        keyType = HS_Common.Any;
        break;
      }
    }
    String valType = HS_TypeOf(value.values.first);
    for (var value in value.values) {
      if (HS_TypeOf(value) != valType) {
        valType = HS_Common.Any;
        break;
      }
    }
    return [keyType, valType];
  } else if (value is HS_Instance) {
    return value.klass.typeParams;
  } else {
    return [];
  }
}

class Field {
  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HS_Value
  dynamic value;

  final String type;
  final List<String> typeParams = [];
  final bool nullable;
  final bool mutable;
  final bool initialized;

  Field(this.type,
      {List<String> typeParams, this.value, this.nullable = false, this.mutable = true, this.initialized = false}) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }
}
