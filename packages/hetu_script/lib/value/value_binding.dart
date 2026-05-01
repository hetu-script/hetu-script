import '../declaration/declaration.dart';

/// A lightweight [HTDeclaration] that holds a mutable value,
/// replacing full [HTVariable] objects where only value get/set is needed.
class HTValueBinding extends HTDeclaration {
  dynamic _value;

  HTValueBinding({super.id, dynamic value})
      : _value = value,
        super(isMutable: true);

  @override
  dynamic get value => _value;

  @override
  set value(dynamic v) => _value = v;

  @override
  dynamic clone() => HTValueBinding(id: id, value: _value);
}
