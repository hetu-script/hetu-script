import 'package:path/path.dart' as path;

import 'binding_models.dart';

/// Emits Dart and Hetu source code from binding models.
class BindingEmitter {
  /// Generates the Dart binding source for a single file.
  ///
  /// [importUri] is the URI used to import the original Dart file. If omitted,
  /// a relative import from [outputPath] to the source file is computed.
  String emitDart(BindingFile file, {String? importUri, String? outputPath}) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Binding for ${file.filePath}');
    buffer.writeln();
    buffer.writeln("import 'package:hetu_script/hetu_script.dart';");
    buffer.writeln("import 'package:hetu_script/binding.dart';");
    buffer.writeln("import '${_importUri(file, importUri, outputPath)}';");
    buffer.writeln();

    for (final declaration in file.declarations) {
      switch (declaration) {
        case BindingClass():
          _emitDartClass(buffer, declaration);
        case BindingEnum():
          _emitDartEnum(buffer, declaration);
        case BindingFunctionType():
          _emitDartFunctionType(buffer, declaration);
      }
    }

    return buffer.toString();
  }

  /// Generates the Hetu script declarations for a single file.
  String emitHetu(BindingFile file) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Binding declarations for ${file.filePath}');
    buffer.writeln();

    for (final declaration in file.declarations) {
      switch (declaration) {
        case BindingClass():
          _emitHetuClass(buffer, declaration);
        case BindingEnum():
          _emitHetuEnum(buffer, declaration);
        case BindingFunctionType():
          _emitHetuFunctionType(buffer, declaration);
      }
    }

    return buffer.toString();
  }

  void _emitDartClass(StringBuffer buffer, BindingClass cls) {
    final className = '${cls.name}ClassBinding';
    buffer.writeln('class $className extends HTExternalClass {');
    buffer.writeln("  $className() : super('${cls.hetuName}');");
    buffer.writeln();

    _emitDartMemberGet(buffer, cls);
    _emitDartMemberSet(buffer, cls);
    _emitDartInstanceMemberGet(buffer, cls);
    _emitDartInstanceMemberSet(buffer, cls);

    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitDartMemberGet(StringBuffer buffer, BindingClass cls) {
    final hasConstructors = cls.constructors.isNotEmpty;
    final hasStaticMethods = cls.staticMethods.isNotEmpty;
    final hasStaticFields = cls.staticFields.isNotEmpty;
    if (!hasConstructors && !hasStaticMethods && !hasStaticFields) {
      return;
    }

    buffer.writeln('  @override');
    buffer.writeln('  dynamic memberGet(String id,');
    buffer.writeln(
        '      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {');
    buffer.writeln('    switch (id) {');

    for (final constructor in cls.constructors) {
      final key = '${cls.hetuName}${constructor.bindingKey}';
      buffer.writeln("      case '$key':");
      buffer.writeln('        return ({positionalArgs, namedArgs}) =>');
      buffer.writeln('            ${_constructorInvocation(cls, constructor)};');
    }

    for (final method in cls.staticMethods) {
      if (method.isGetter) {
        buffer.writeln("      case '${cls.hetuName}.${method.hetuName}':");
        buffer.writeln('        return ${cls.name}.${method.name};');
      } else if (!method.isSetter) {
        buffer.writeln("      case '${cls.hetuName}.${method.hetuName}':");
        buffer.writeln('        return ({positionalArgs, namedArgs}) =>');
        buffer.writeln('            ${cls.name}.${method.name}${_invokeParams(method.parameters)};');
      }
    }

    for (final field in cls.staticFields) {
      buffer.writeln("      case '${cls.hetuName}.${field.hetuName}':");
      buffer.writeln('        return ${cls.name}.${field.name};');
    }

    buffer.writeln('      default:');
    buffer.writeln('        if (!ignoreUndefined) throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _emitDartMemberSet(StringBuffer buffer, BindingClass cls) {
    final setters = cls.staticMethods.where((m) => m.isSetter).toList();
    final fields = cls.staticFields.where((f) => f.hasSetter).toList();
    if (setters.isEmpty && fields.isEmpty) {
      return;
    }

    buffer.writeln('  @override');
    buffer.writeln('  void memberSet(String id, dynamic value,');
    buffer.writeln('      {String? from, bool defineIfAbsent = false}) {');
    buffer.writeln('    switch (id) {');

    for (final method in setters) {
      buffer.writeln("      case '${cls.hetuName}.${method.hetuName}':");
      buffer.writeln('        ${cls.name}.${method.name} = value;');
    }

    for (final field in fields) {
      buffer.writeln("      case '${cls.hetuName}.${field.hetuName}':");
      buffer.writeln('        ${cls.name}.${field.name} = value;');
    }

    buffer.writeln('      default:');
    buffer.writeln('        throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _emitDartInstanceMemberGet(StringBuffer buffer, BindingClass cls) {
    if (cls.instanceMethods.isEmpty && cls.instanceFields.isEmpty) {
      return;
    }

    buffer.writeln('  @override');
    buffer.writeln('  dynamic instanceMemberGet(dynamic instance, String id,');
    buffer.writeln('      {bool ignoreUndefined = false}) {');
    buffer.writeln('    final object = instance as ${cls.name};');
    buffer.writeln('    switch (id) {');

    for (final method in cls.instanceMethods) {
      if (method.isGetter) {
        buffer.writeln("      case '${method.hetuName}':");
        buffer.writeln('        return object.${method.name};');
      } else if (!method.isSetter) {
        buffer.writeln("      case '${method.hetuName}':");
        buffer.writeln('        return ({object, positionalArgs, namedArgs}) =>');
        buffer.writeln('            object.${method.name}${_invokeParams(method.parameters)};');
      }
    }

    for (final field in cls.instanceFields) {
      buffer.writeln("      case '${field.hetuName}':");
      buffer.writeln('        return object.${field.name};');
    }

    buffer.writeln('      default:');
    buffer.writeln('        if (!ignoreUndefined) throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _emitDartInstanceMemberSet(StringBuffer buffer, BindingClass cls) {
    final setters = cls.instanceMethods.where((m) => m.isSetter).toList();
    final fields = cls.instanceFields.where((f) => f.hasSetter).toList();
    if (setters.isEmpty && fields.isEmpty) {
      return;
    }

    buffer.writeln('  @override');
    buffer.writeln('  void instanceMemberSet(dynamic instance, String id, dynamic value,');
    buffer.writeln('      {bool ignoreUndefined = false}) {');
    buffer.writeln('    final object = instance as ${cls.name};');
    buffer.writeln('    switch (id) {');

    for (final method in setters) {
      buffer.writeln("      case '${method.hetuName}':");
      buffer.writeln('        object.${method.name} = value;');
    }

    for (final field in fields) {
      buffer.writeln("      case '${field.hetuName}':");
      buffer.writeln('        object.${field.name} = value;');
    }

    buffer.writeln('      default:');
    buffer.writeln('        if (!ignoreUndefined) throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _emitDartEnum(StringBuffer buffer, BindingEnum enum_) {
    final className = '${enum_.name}ClassBinding';
    buffer.writeln('class $className extends HTExternalClass {');
    buffer.writeln("  $className() : super('${enum_.hetuName}');");
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  dynamic memberGet(String id,');
    buffer.writeln(
        '      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {');
    buffer.writeln('    switch (id) {');
    buffer.writeln("      case '${enum_.hetuName}.values':");
    buffer.writeln('        return ${enum_.name}.values;');
    for (final constant in enum_.constants) {
      buffer.writeln("      case '${enum_.hetuName}.$constant':");
      buffer.writeln('        return ${enum_.name}.$constant;');
    }
    buffer.writeln('      default:');
    buffer.writeln('        if (!ignoreUndefined) throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  dynamic instanceMemberGet(dynamic instance, String id,');
    buffer.writeln('      {bool ignoreUndefined = false}) {');
    buffer.writeln('    final object = instance as ${enum_.name};');
    buffer.writeln('    switch (id) {');
    buffer.writeln("      case 'index':");
    buffer.writeln('        return object.index;');
    buffer.writeln("      case 'name':");
    buffer.writeln('        return object.name;');
    buffer.writeln("      case 'toString':");
    buffer.writeln('        return ({positionalArgs, namedArgs}) => object.toString();');
    buffer.writeln('      default:');
    buffer.writeln('        if (!ignoreUndefined) throw HTError.undefined(id);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitDartFunctionType(StringBuffer buffer, BindingFunctionType type) {
    // Function typedef wrappers are generated as top-level functions that can
    // be passed to Hetu.init(externalFunctionTypedef: ...).
    final name = '${type.name}Binding';
    buffer.writeln('Function $name(HTFunction function) {');
    buffer.writeln('  return (${_dartParams(type.parameters)}) {');
    buffer.writeln('    return function.call(');
    buffer.writeln('      positionalArgs: [${_positionalArgs(type.parameters)}],');
    buffer.writeln('      namedArgs: {${_namedArgs(type.parameters)}},');
    buffer.writeln('    )${_returnCast(type.returnType)};');
    buffer.writeln('  };');
    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitHetuClass(StringBuffer buffer, BindingClass cls) {
    buffer.writeln('external class ${cls.hetuName} {');
    for (final constructor in cls.constructors) {
      final name = constructor.hetuName;
      if (name == null) {
        buffer.writeln('  constructor(${_hetuParams(constructor.parameters)})');
      } else {
        buffer.writeln('  constructor $name(${_hetuParams(constructor.parameters)})');
      }
    }
    for (final field in cls.staticFields) {
      if (field.hasSetter) {
        buffer.writeln('  static var ${field.hetuName}');
      } else {
        buffer.writeln('  static get ${field.hetuName}');
      }
    }
    for (final method in cls.staticMethods) {
      if (method.isGetter) {
        buffer.writeln('  static get ${method.hetuName}');
      } else if (method.isSetter) {
        buffer.writeln('  static set ${method.hetuName}(value)');
      } else {
        buffer.writeln('  static function ${method.hetuName}(${_hetuParams(method.parameters)})');
      }
    }
    for (final field in cls.instanceFields) {
      if (field.hasSetter) {
        buffer.writeln('  var ${field.hetuName}');
      } else {
        buffer.writeln('  get ${field.hetuName}');
      }
    }
    for (final method in cls.instanceMethods) {
      if (method.isGetter) {
        buffer.writeln('  get ${method.hetuName}');
      } else if (method.isSetter) {
        buffer.writeln('  set ${method.hetuName}(value)');
      } else {
        buffer.writeln('  function ${method.hetuName}(${_hetuParams(method.parameters)})');
      }
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitHetuEnum(StringBuffer buffer, BindingEnum enum_) {
    buffer.writeln('external class ${enum_.hetuName} {');
    buffer.writeln('  static get values');
    for (final constant in enum_.constants) {
      buffer.writeln('  static get $constant');
    }
    buffer.writeln('  get index');
    buffer.writeln('  get name');
    buffer.writeln('  function toString()');
    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitHetuFunctionType(StringBuffer buffer, BindingFunctionType type) {
    buffer.writeln('// Function typedef ${type.hetuName} is used for Dart interop.');
    buffer.writeln();
  }

  String _constructorInvocation(BindingClass cls, BindingConstructor constructor) {
    final name = constructor.name;
    final constructorName = name == null ? '' : '.$name';
    return '${cls.name}$constructorName${_invokeParams(constructor.parameters)}';
  }

  String _invokeParams(List<BindingParameter> parameters) {
    final positional = <String>[];
    final named = <String>[];
    var index = 0;
    for (final param in parameters) {
      if (param.isPositional) {
        var value = 'positionalArgs[$index]';
        if (param.isOptional) {
          value = 'positionalArgs.length > $index ? $value : ${param.defaultValue ?? 'null'}';
        }
        positional.add(value);
        index++;
      } else if (param.isNamed) {
        var value = "namedArgs['${param.name}']";
        if (!param.isRequired) {
          value = "namedArgs.containsKey('${param.name}') ? $value : ${param.defaultValue ?? 'null'}";
        }
        named.add('${param.name}: $value');
      }
    }
    final parts = <String>[];
    if (positional.isNotEmpty) {
      parts.add(positional.join(', '));
    }
    if (named.isNotEmpty) {
      parts.add(named.join(', '));
    }
    return '(${parts.join(', ')})';
  }

  String _hetuParams(List<BindingParameter> parameters) {
    final positional = <String>[];
    final optionalPositional = <String>[];
    final named = <String>[];
    for (final param in parameters) {
      final type = param.type != null ? ': ${_hetuType(param.type)}' : '';
      final defaultValue = param.defaultValue != null ? ' = ${param.defaultValue}' : '';
      if (param.isNamed) {
        named.add('${param.hetuName}$type$defaultValue');
      } else if (param.isOptional) {
        optionalPositional.add('${param.hetuName}$type$defaultValue');
      } else {
        positional.add('${param.hetuName}$type');
      }
    }
    final parts = <String>[];
    if (positional.isNotEmpty) {
      parts.add(positional.join(', '));
    }
    if (optionalPositional.isNotEmpty) {
      parts.add('[${optionalPositional.join(', ')}]');
    }
    if (named.isNotEmpty) {
      parts.add('{${named.join(', ')}}');
    }
    return parts.join(', ');
  }

  String _dartParams(List<BindingParameter> parameters) {
    final positional = <String>[];
    final optionalPositional = <String>[];
    final named = <String>[];
    for (final param in parameters) {
      final type = param.type != null ? '${param.type} ' : '';
      if (param.isNamed) {
        final required = param.isRequired ? 'required ' : '';
        named.add('$required$type${param.name}');
      } else if (param.isOptional) {
        optionalPositional.add('$type${param.name}');
      } else {
        positional.add('$type${param.name}');
      }
    }
    final parts = <String>[];
    if (positional.isNotEmpty) {
      parts.add(positional.join(', '));
    }
    if (optionalPositional.isNotEmpty) {
      parts.add('[${optionalPositional.join(', ')}]');
    }
    if (named.isNotEmpty) {
      parts.add('{${named.join(', ')}}');
    }
    return parts.join(', ');
  }

  String _positionalArgs(List<BindingParameter> parameters) {
    return parameters.where((p) => p.isPositional).map((p) => p.name).join(', ');
  }

  String _namedArgs(List<BindingParameter> parameters) {
    return parameters
        .where((p) => p.isNamed)
        .map((p) => "'${p.name}': ${p.name}")
        .join(', ');
  }

  String _returnCast(String returnType) {
    if (returnType == 'void' || returnType == 'dynamic' || returnType == 'any') {
      return '';
    }
    return ' as $returnType';
  }

  String _importUri(BindingFile file, String? importUri, String? outputPath) {
    if (importUri != null) {
      return importUri;
    }
    if (outputPath != null) {
      final relative = path.relative(file.filePath, from: outputPath);
      return relative.replaceAll('\\', '/');
    }
    return path.basename(file.filePath);
  }

  String _hetuType(String? dartType) {
    if (dartType == null) return 'any';
    const mapping = {
      'String': 'string',
      'int': 'integer',
      'double': 'float',
      'num': 'number',
      'bool': 'bool',
      'void': 'void',
      'dynamic': 'any',
    };
    return mapping[dartType] ?? dartType;
  }
}
