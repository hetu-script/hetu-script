import '../declaration/declaration.dart';

class HTConst extends HTDeclaration {
  final String _id;

  @override
  String get id => _id;

  @override
  final dynamic value;

  HTConst(this._id, {this.value}) : super(id: _id);

  @override
  HTConst clone() => HTConst(_id, value: value);
}
