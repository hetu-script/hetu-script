import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:hetu_script/binding.dart';
import 'package:source_gen/source_gen.dart';

import 'binding_emitter.dart';
import 'binding_models.dart';
import 'binding_resolver.dart';

/// A build_runner generator that produces Hetu binding code for classes,
/// enums, and function typedefs annotated with `@HTBinding()`.
class HTBindingGenerator extends GeneratorForAnnotation<HTBinding> {
  const HTBindingGenerator();

  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final filePath = buildStep.inputId.path;
    final resolver = BindingResolver(includedPaths: const []);
    final emitter = BindingEmitter();

    BindingDeclaration? declaration;
    if (element is ClassElement) {
      declaration = resolver.resolveClassElement(element, filePath);
    } else if (element is EnumElement) {
      declaration = resolver.resolveEnumElement(element, filePath);
    } else if (element is TypeAliasElement) {
      declaration = resolver.resolveFunctionTypeElement(element, filePath);
    }

    if (declaration == null) {
      return null;
    }

    final file = BindingFile(filePath: filePath, declarations: [declaration]);
    return emitter.emitDart(file);
  }
}
