import 'package:path/path.dart' as path;

import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../grammar/constant.dart';
import '../source/source.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';

/// Handle import statement in sources and bundle
/// all related sources into a single compilation
class HTBundler {
  final HTResourceContext<HTSource> sourceContext;

  HTBundler({required this.sourceContext});

  /// Parse a string content and generate a library,
  /// will import other files.
  ASTCompilation bundle(
      {required HTSource source,
      required HTParser parser,
      bool normalizePath = true}) {
    final result = parser.parseSource(source);
    final parserErrors = result.errors!;
    final values = <String, ASTSource>{};
    final sources = <String, ASTSource>{};
    final Set _cachedParsingTargets = <String>{};
    void handleImport(ASTSource result) {
      _cachedParsingTargets.add(result.fullName);
      for (final decl in result.imports) {
        if (decl.isPreloadedModule) {
          decl.fullName = decl.fromPath;
          continue;
        }
        try {
          late final ASTSource importedSource;
          String importFullName;
          if (normalizePath) {
            final currentDir =
                result.fullName.startsWith(InternalIdentifier.anonymousScript)
                    ? sourceContext.root
                    : path.dirname(result.fullName);
            decl.fullName = importFullName = sourceContext.getAbsolutePath(
                key: decl.fromPath!, dirName: currentDir);
          } else {
            decl.fullName = importFullName = decl.fromPath!;
          }
          if (_cachedParsingTargets.contains(importFullName)) {
            continue;
          }
          // else if (_cachedParseResults.containsKey(importFullName)) {
          //   importedSource = _cachedParseResults[importFullName]!;
          // }
          else {
            final source2 = sourceContext.getResource(importFullName);
            importedSource = parser.parseSource(source2);
            // final parser2 = HTParser(sourceContext: sourceContext);
            // importedSource = parser2.parseSource(source2);
            parserErrors.addAll(importedSource.errors!);
            // _cachedParseResults[importFullName] = importedSource;
          }
          if (importedSource.resourceType == HTResourceType.hetuValue) {
            values[importFullName] = importedSource;
          } else {
            handleImport(importedSource);
            sources[importFullName] = importedSource;
          }
        } catch (error) {
          final convertedError = HTError.sourceProviderError(decl.fromPath!,
              filename: source.fullName,
              line: decl.line,
              column: decl.column,
              offset: decl.offset,
              length: decl.length);
          parserErrors.add(convertedError);
        }
      }
      _cachedParsingTargets.remove(result.fullName);
    }

    if (result.resourceType == HTResourceType.hetuValue) {
      values[result.fullName] = result;
    } else {
      handleImport(result);
      sources[result.fullName] = result;
    }
    final compilation = ASTCompilation(
        values: values,
        sources: sources,
        entryResourceName: source.fullName,
        entryResourceType: source.type,
        errors: parserErrors);
    return compilation;
  }
}
