import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'binding_models.dart';

/// Extracts binding models from Dart source files using the analyzer's
/// resolved AST.
class BindingResolver {
  /// Keywords in Hetu that cannot be used as identifiers directly.
  static const _hetuKeywords = <String>{
    'null',
    'true',
    'false',
    'void',
    'type',
    'import',
    'export',
    'from',
    'any',
    'unknown',
    'never',
    'var',
    'final',
    'const',
    'def',
    'delete',
    'typeof',
    'namespace',
    'class',
    'enum',
    'function',
    'struct',
    'this',
    'super',
    'abstract',
    'override',
    'external',
    'static',
    'extends',
    'implements',
    'with',
    'new',
    'constructor',
    'factory',
    'get',
    'set',
    'async',
    'await',
    'break',
    'continue',
    'return',
    'for',
    'in',
    'of',
    'if',
    'else',
    'while',
    'do',
    'switch',
    'is',
    'as',
  };

  final AnalysisContextCollection _collection;

  BindingResolver({required List<String> includedPaths})
      : _collection = AnalysisContextCollection(includedPaths: includedPaths);

  /// Resolves a single Dart file and returns its binding declarations.
  Future<BindingFile> resolveFile(String filePath) async {
    final context = _collection.contextFor(filePath);
    final result = await context.currentSession.getResolvedUnit(filePath);
    if (result is! ResolvedUnitResult) {
      throw StateError('Unable to resolve Dart file: $filePath');
    }

    final declarations = <BindingDeclaration>[];
    for (final declaration in result.unit.declarations) {
      final model = _resolveDeclaration(declaration, filePath);
      if (model != null) {
        declarations.add(model);
      }
    }

    return BindingFile(filePath: filePath, declarations: declarations);
  }

  BindingDeclaration? _resolveDeclaration(
    CompilationUnitMember declaration,
    String filePath,
  ) {
    if (declaration is ClassDeclaration) {
      final fragment = declaration.declaredFragment;
      final element = fragment?.element;
      if (element == null || !_hasBindingAnnotation(element)) {
        return null;
      }
      return resolveClassElement(element, filePath);
    } else if (declaration is EnumDeclaration) {
      return _resolveEnum(declaration, filePath);
    } else if (declaration is GenericTypeAlias) {
      return _resolveGenericTypeAlias(declaration, filePath);
    } else if (declaration is FunctionTypeAlias) {
      return _resolveFunctionTypeAlias(declaration, filePath);
    }
    return null;
  }

  BindingClass? resolveClassElement(ClassElement element, String filePath) {
    if (element.isPrivate) {
      return null;
    }

    final name = element.name;
    if (name == null) {
      return null;
    }

    final constructors = <BindingConstructor>[];
    final staticMethods = <BindingMethod>[];
    final instanceMethods = <BindingMethod>[];
    final staticFields = <BindingField>[];
    final instanceFields = <BindingField>[];

    for (final constructor in element.constructors) {
      if (constructor.isPrivate) continue;
      constructors.add(_resolveConstructor(constructor));
    }

    for (final method in element.methods) {
      if (method.isPrivate || _isDeprecated(method)) continue;
      final model = _resolveMethod(method);
      if (method.isStatic) {
        staticMethods.add(model);
      } else {
        instanceMethods.add(model);
      }
    }

    for (final getter in element.getters) {
      if (getter.isPrivate || _isDeprecated(getter)) continue;
      if (!getter.isOriginDeclaration) continue;
      final model = _resolveAccessor(getter);
      if (getter.isStatic) {
        staticMethods.add(model);
      } else {
        instanceMethods.add(model);
      }
    }

    for (final setter in element.setters) {
      if (setter.isPrivate || _isDeprecated(setter)) continue;
      if (!setter.isOriginDeclaration) continue;
      final model = _resolveAccessor(setter);
      if (setter.isStatic) {
        staticMethods.add(model);
      } else {
        instanceMethods.add(model);
      }
    }

    for (final field in element.fields) {
      if (field.isPrivate || _isDeprecated(field)) continue;
      if (!field.isOriginDeclaration) continue;
      final model = _resolveField(field);
      if (field.isStatic) {
        staticFields.add(model);
      } else {
        instanceFields.add(model);
      }
    }

    return BindingClass(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      filePath: filePath,
      constructors: constructors,
      staticMethods: staticMethods,
      instanceMethods: instanceMethods,
      staticFields: staticFields,
      instanceFields: instanceFields,
      superClassName: element.supertype?.element.name,
      isAbstract: element.isAbstract,
    );
  }

  BindingEnum? resolveEnumElement(EnumElement element, String filePath) {
    if (element.isPrivate) {
      return null;
    }

    final name = element.name;
    if (name == null) {
      return null;
    }

    final constants = <String>[];
    for (final constant in element.constants) {
      final constantName = constant.name;
      if (constantName != null) {
        constants.add(constantName);
      }
    }

    return BindingEnum(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      filePath: filePath,
      constants: constants,
    );
  }

  BindingEnum? _resolveEnum(EnumDeclaration node, String filePath) {
    final fragment = node.declaredFragment;
    final element = fragment?.element;
    if (element == null || !_hasBindingAnnotation(element)) {
      return null;
    }
    return resolveEnumElement(element, filePath);
  }

  BindingFunctionType? resolveFunctionTypeElement(
    TypeAliasElement element,
    String filePath,
  ) {
    if (element.isPrivate) {
      return null;
    }

    final name = element.name;
    if (name == null) {
      return null;
    }

    final aliasedType = element.aliasedType;
    if (aliasedType is! FunctionType) {
      return null;
    }

    return BindingFunctionType(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      filePath: filePath,
      parameters: _resolveParameters(aliasedType.formalParameters),
      returnType: _typeName(aliasedType.returnType),
    );
  }

  BindingFunctionType? _resolveGenericTypeAlias(
    GenericTypeAlias node,
    String filePath,
  ) {
    final fragment = node.declaredFragment;
    final element = fragment?.element;
    if (element is! TypeAliasElement || !_hasBindingAnnotation(element)) {
      return null;
    }
    return resolveFunctionTypeElement(element, filePath);
  }

  BindingFunctionType? _resolveFunctionTypeAlias(
    FunctionTypeAlias node,
    String filePath,
  ) {
    final fragment = node.declaredFragment;
    final element = fragment?.element;
    if (element is! TypeAliasElement || !_hasBindingAnnotation(element)) {
      return null;
    }
    return resolveFunctionTypeElement(element, filePath);
  }

  BindingConstructor _resolveConstructor(ConstructorElement element) {
    final name = element.name;
    final isDefault = name == null || name == 'new';
    return BindingConstructor(
      name: isDefault ? null : name,
      hetuName: isDefault ? null : _escapeHetuKeyword(name),
      parameters: _resolveParameters(element.formalParameters),
      isFactory: element.isFactory,
      isConst: element.isConst,
    );
  }

  BindingMethod _resolveMethod(MethodElement element) {
    final name = element.name;
    if (name == null) {
      throw StateError('Method has no name: $element');
    }
    return BindingMethod(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      parameters: _resolveParameters(element.formalParameters),
      returnType: _typeName(element.returnType),
      isStatic: element.isStatic,
    );
  }

  BindingMethod _resolveAccessor(PropertyAccessorElement element) {
    final name = element.name;
    if (name == null) {
      throw StateError('Accessor has no name: $element');
    }
    return BindingMethod(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      parameters: _resolveParameters(element.formalParameters),
      returnType: _typeName(element.returnType),
      isStatic: element.isStatic,
      isGetter: element is GetterElement,
      isSetter: element is SetterElement,
    );
  }

  BindingField _resolveField(FieldElement element) {
    final name = element.name;
    if (name == null) {
      throw StateError('Field has no name: $element');
    }
    return BindingField(
      name: name,
      hetuName: _escapeHetuKeyword(name),
      type: _typeName(element.type),
      isStatic: element.isStatic,
      isFinal: element.isFinal,
      isConst: element.isConst,
    );
  }

  List<BindingParameter> _resolveParameters(
    List<FormalParameterElement> parameters,
  ) {
    return parameters.map((parameter) {
      final name = parameter.name;
      if (name == null) {
        throw StateError('Parameter has no name: $parameter');
      }
      return BindingParameter(
        name: name,
        hetuName: _escapeHetuKeyword(name),
        type: _typeName(parameter.type),
        defaultValue: parameter.defaultValueCode,
        isPositional: parameter.isPositional,
        isOptional: parameter.isOptional,
        isNamed: parameter.isNamed,
        isRequired: parameter.isRequired,
      );
    }).toList();
  }

  bool _hasBindingAnnotation(Element element) {
    for (final annotation in element.metadata.annotations) {
      final annotationElement = annotation.element;
      if (annotationElement == null) continue;
      final name = annotationElement.name;
      if (name == 'HTBinding') {
        return true;
      }
      final enclosingName = annotationElement.enclosingElement?.name;
      if (enclosingName == 'HTBinding') {
        return true;
      }
    }
    return false;
  }

  bool _isDeprecated(Element element) {
    for (final annotation in element.metadata.annotations) {
      if (annotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  String _typeName(DartType type) {
    return type.getDisplayString();
  }

  String _escapeHetuKeyword(String name) {
    if (_hetuKeywords.contains(name)) {
      return '${name}_alias';
    }
    return name;
  }
}
