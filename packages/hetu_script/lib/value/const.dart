import '../interpreter/const_table.dart';
import '../declaration/declaration.dart';

enum ConstType {
  intValue,
  floatValue,
  stringValue,
}

class HTConst extends HTDeclaration {
  final String _id;

  @override
  String get id => _id;

  @override
  bool get isConst => true;

  final int _index;

  final ConstType _type;

  final ConstTable _table;

  HTConst(
    this._id,
    this._type,
    this._index,
    this._table, {
    String? classId,
    bool isStatic = false,
    bool isTopLevel = false,
  }) : super(
            id: _id,
            classId: classId,
            isStatic: isStatic,
            isTopLevel: isTopLevel);

  @override
  dynamic get value {
    switch (_type) {
      case ConstType.intValue:
        return _table.getInt64(_index);
      case ConstType.floatValue:
        return _table.getFloat64(_index);
      case ConstType.stringValue:
        return _table.getUtf8String(_index);
    }
  }

  @override
  HTConst clone() => this;
}
