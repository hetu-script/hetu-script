import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

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
  ASTCompilation bundle({
    required HTSource source,
    required HTParser parser,
    bool normalizePath = true,
    bool printPerformanceStatistics = false,
    Version? version,
  }) {
    final sourceParseResult = parser.parseSource(source,
        printPerformanceStatistics: printPerformanceStatistics);
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
          if (normalizePath) {
            final currentDir = astSource.fullName
                    .startsWith(InternalIdentifier.anonymousScript)
                ? sourceContext.root
                : path.dirname(astSource.fullName);
            decl.fullFromPath = importFullName = sourceContext.getAbsolutePath(
                key: decl.fromPath!, dirName: currentDir);
          } else {
            decl.fullFromPath = importFullName = decl.fromPath!;
          }
          if (sources.keys.contains(importFullName) ||
              cachedParsingTargets.contains(importFullName)) continue;
          final source2 = sourceContext.getResource(importFullName);
          importedSource = parser.parseSource(source2,
              printPerformanceStatistics: printPerformanceStatistics);
          // final parser2 = HTParser(sourceContext: sourceContext);
          // importedSource = parser2.parseSource(source2);
          sourceParseErrors.addAll(importedSource.errors);
          // _cachedParseResults[importFullName] = importedSource;
          if (importedSource.resourceType == HTResourceType.hetuValue) {
            values[importFullName] = importedSource;
          } else {
            handleImport(importedSource);
            sources[importFullName] = importedSource;
          }
        } catch (error) {
          if (error is HTError &&
              error.code != ErrorCode.resourceDoesNotExist) {
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
        }
      }
      cachedParsingTargets.remove(astSource.fullName);
    }

    if (sourceParseResult.resourceType == HTResourceType.hetuValue) {
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
    final tok = DateTime.now().millisecondsSinceEpoch;
    if (printPerformanceStatistics) {
      print('hetu: ${tok - tik}ms\tto bundle\t[${source.fullName}]');
    }
    return compilation;
  }
}
