/// Semantic models for Hetu external binding generation.
///
/// These models are immutable descriptions of Dart declarations that are
/// marked with `@HTBinding()`. They are produced by [BindingResolver] and
/// consumed by emitters to generate Dart and Hetu source code.
library;

/// Base class for all binding declaration models.
sealed class BindingDeclaration {
  /// The original Dart name of the declaration.
  final String name;

  /// The name used in generated Hetu code. Differs from [name] when the
  /// original name is a Hetu keyword.
  final String hetuName;

  /// The file path where this declaration is defined.
  final String filePath;

  const BindingDeclaration({
    required this.name,
    required this.hetuName,
    required this.filePath,
  });
}

/// A Dart class marked for binding.
final class BindingClass extends BindingDeclaration {
  final List<BindingConstructor> constructors;
  final List<BindingMethod> staticMethods;
  final List<BindingMethod> instanceMethods;
  final List<BindingField> staticFields;
  final List<BindingField> instanceFields;
  final String? superClassName;
  final bool isAbstract;

  const BindingClass({
    required super.name,
    required super.hetuName,
    required super.filePath,
    required this.constructors,
    required this.staticMethods,
    required this.instanceMethods,
    required this.staticFields,
    required this.instanceFields,
    this.superClassName,
    this.isAbstract = false,
  });
}

/// A Dart enum marked for binding.
final class BindingEnum extends BindingDeclaration {
  final List<String> constants;

  const BindingEnum({
    required super.name,
    required super.hetuName,
    required super.filePath,
    required this.constants,
  });
}

/// A Dart function typedef marked for binding.
final class BindingFunctionType extends BindingDeclaration {
  final List<BindingParameter> parameters;
  final String returnType;

  const BindingFunctionType({
    required super.name,
    required super.hetuName,
    required super.filePath,
    required this.parameters,
    required this.returnType,
  });
}

/// A constructor of a bound class.
final class BindingConstructor {
  /// The constructor name, or `null` for the default constructor.
  final String? name;

  /// The name used in generated code (may differ from [name] for keywords).
  final String? hetuName;

  final List<BindingParameter> parameters;
  final bool isFactory;
  final bool isConst;

  const BindingConstructor({
    this.name,
    this.hetuName,
    required this.parameters,
    this.isFactory = false,
    this.isConst = false,
  });

  /// The key used in `memberGet` for this constructor.
  String get bindingKey => name == null ? '' : '.$name';
}

/// A method of a bound class.
final class BindingMethod {
  final String name;
  final String hetuName;
  final List<BindingParameter> parameters;
  final String? returnType;
  final bool isStatic;
  final bool isGetter;
  final bool isSetter;

  const BindingMethod({
    required this.name,
    required this.hetuName,
    required this.parameters,
    this.returnType,
    this.isStatic = false,
    this.isGetter = false,
    this.isSetter = false,
  });
}

/// A field of a bound class.
final class BindingField {
  final String name;
  final String hetuName;
  final String? type;
  final bool isStatic;
  final bool isFinal;
  final bool isConst;

  const BindingField({
    required this.name,
    required this.hetuName,
    this.type,
    this.isStatic = false,
    this.isFinal = false,
    this.isConst = false,
  });

  bool get hasSetter => !isFinal && !isConst;
}

/// A parameter of a constructor, method, or function type.
final class BindingParameter {
  final String name;
  final String hetuName;
  final String? type;
  final String? defaultValue;
  final bool isPositional;
  final bool isOptional;
  final bool isNamed;
  final bool isRequired;

  const BindingParameter({
    required this.name,
    required this.hetuName,
    this.type,
    this.defaultValue,
    this.isPositional = true,
    this.isOptional = false,
    this.isNamed = false,
    this.isRequired = false,
  });
}

/// The result of resolving a single Dart source file.
final class BindingFile {
  final String filePath;
  final List<BindingDeclaration> declarations;

  const BindingFile({
    required this.filePath,
    required this.declarations,
  });

  Iterable<BindingClass> get classes => declarations.whereType<BindingClass>();
  Iterable<BindingEnum> get enums => declarations.whereType<BindingEnum>();
  Iterable<BindingFunctionType> get functionTypes =>
      declarations.whereType<BindingFunctionType>();

  bool get isEmpty => declarations.isEmpty;
}
