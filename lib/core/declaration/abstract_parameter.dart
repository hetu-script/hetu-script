abstract class AbstractParameter {
  String get paramId;

  /// Wether this is an optional parameter.
  bool get isOptional;

  /// Wether this is a named parameter.
  bool get isNamed;

  /// Wether this is a variadic parameter.
  bool get isVariadic;
}
