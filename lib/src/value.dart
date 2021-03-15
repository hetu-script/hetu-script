import 'type.dart';
import 'function.dart';
import 'common.dart';
import 'lexicon.dart';

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

  bool contains(String varName);
  void define(String id, CodeRunner interpreter,
      {int? line,
      int? column,
      HT_TypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false});

  dynamic fetch(String varName, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true});

  void assign(String varName, dynamic value, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true});
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
