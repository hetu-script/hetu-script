import '../declaration/declaration.dart';

class HTConst extends HTDeclaration {
  @override
  final String id;

  @override
  final dynamic value;

  HTConst(this.id, {this.value}) : super(id: id);

  @override
  HTConst clone() => HTConst(id, value: value);
}
