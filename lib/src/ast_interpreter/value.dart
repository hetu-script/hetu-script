import 'type.dart';
import 'function.dart';
import '../interpreter.dart';
import '../lexicon.dart';

class _HTNull with HTType {
  const _HTNull();

  @override
  HTTypeId get typeid => HTTypeId.NULL;
}

/// Value是命名空间、类和实例的基类
abstract class HTValue {
  static const NULL = _HTNull();

  final String id;
  //bool used = false;

  HTValue(this.id);

  bool contains(String varName);
  void define(String id, Interpreter interpreter,
      {int? line,
      int? column,
      HTTypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false});

  dynamic fetch(String varName, int? line, int? column, Interpreter interpreter,
      {bool error = true, String from = HTLexicon.global, bool recursive = true});

  void assign(String varName, dynamic value, int? line, int? column, Interpreter interpreter,
      {bool error = true, String from = HTLexicon.global, bool recursive = true});
}

class HTDeclaration {
  final String id;

  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HTValue
  dynamic value;
  HTFunction? getter;
  HTFunction? setter;

  final HTTypeId declType;
  final bool isExtern;
  final bool isNullable;
  final bool isImmutable;

  HTDeclaration(this.id,
      {this.value,
      this.getter,
      this.setter,
      this.declType = HTTypeId.ANY,
      this.isExtern = false,
      this.isNullable = false,
      this.isImmutable = false});
}
