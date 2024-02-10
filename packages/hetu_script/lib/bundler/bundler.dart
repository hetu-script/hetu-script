import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../source/source.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';
import '../common/internal_identifier.dart';

class BundlerConfig {
  bool normalizeImportPath;

  bool printPerformanceStatistics;

  BundlerConfig({
    this.normalizeImportPath = true,
    this.printPerformanceStatistics = false,
  });
}

/// Handle import statement in sources and bundle
/// all related sources into a single compilation
class HTBundler {
  BundlerConfig config;

  final HTResourceContext<HTSource> sourceContext;

  HTBundler({
    BundlerConfig? config,
    required this.sourceContext,
  }) : config = config ?? BundlerConfig();

  /// Parse a string content and generate a library,
  /// will import other files.
  ASTCompilation bundle({
    required HTSource source,
    required HTParser parser,
    Version? version,
  }) {
    final sourceParseResult = parser.parseSource(source);
    final tik = DateTime.now().millisecondsSinceEpoch;
    final sourceParseErrors = sourceParseResult.errors;
    final values = <String, ASTSource>{};
    final sources = <String, ASTSource>{};
    final Set cachedParsingTargets = <String>{};
    void handleImport(ASTSource astSource) {
      cachedParsingTargets.add(astSource.fullName);
      for (final decl in astSource.imports) {
        try {
          if (decl.isPreloadedModule) {
            decl.fullFromPath = decl.fromPath;
            continue;
          }
          late final ASTSource importedSource;
          String importFullName;
          if (config.normalizeImportPath) {
            var currentDir = astSource.fullName
                    .startsWith(InternalIdentifier.anonymousScript)
                ? sourceContext.root
                : path.dirname(astSource.fullName);
            if (!currentDir.endsWith('/')) {
              currentDir += '/';
            }
            decl.fullFromPath = importFullName = sourceContext.getAbsolutePath(
                key: decl.fromPath!, dirName: currentDir);
          } else {
            decl.fullFromPath = importFullName = decl.fromPath!;
          }
          if (sources.keys.contains(importFullName) ||
              cachedParsingTargets.contains(importFullName)) continue;
          final source2 = sourceContext.getResource(importFullName);
          importedSource = parser.parseSource(source2);
          // final parser2 = HTParser(sourceContext: sourceContext);
          // importedSource = parser2.parseSource(source2);
          sourceParseErrors.addAll(importedSource.errors);
          // _cachedParseResults[importFullName] = importedSource;
          if (importedSource.resourceType == HTResourceType.json) {
            values[importFullName] = importedSource;
          } else {
            handleImport(importedSource);
            sources[importFullName] = importedSource;
          }
        } catch (error) {
          if (error is HTError) {
            if (error.code != ErrorCode.resourceDoesNotExist) {
              sourceParseErrors.add(error);
            } else {
              final convertedError = HTError.sourceProviderError(
                  decl.fromPath!, astSource.fullName,
                  filename: source.fullName,
                  line: decl.line,
                  column: decl.column,
                  offset: decl.offset,
                  length: decl.length);
              sourceParseErrors.add(convertedError);
            }
          } else {
            final convertedError = HTError.extern(error.toString(),
                filename: source.fullName,
                line: decl.line,
                column: decl.column,
                offset: decl.offset,
                length: decl.length);
            sourceParseErrors.add(convertedError);
          }
        }
      }
      cachedParsingTargets.remove(astSource.fullName);
    }

    if (sourceParseResult.resourceType == HTResourceType.json) {
      values[sourceParseResult.fullName] = sourceParseResult;
    } else {
      handleImport(sourceParseResult);
      sources[sourceParseResult.fullName] = sourceParseResult;
    }
    final compilation = ASTCompilation(
      values: values,
      sources: sources,
      entryFullname: source.fullName,
      entryResourceType: source.type,
      errors: sourceParseErrors,
      version: version,
    );
    if (config.printPerformanceStatistics) {
      final tok = DateTime.now().millisecondsSinceEpoch;
      print('hetu: ${tok - tik}ms\tto bundle\t[${source.fullName}]');
    }
    return compilation;
  }
}
