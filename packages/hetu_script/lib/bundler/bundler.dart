import 'package:hetu_script/parser/parser_default_impl.dart';
import 'package:path/path.dart' as path;

import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../grammar/constant.dart';
import '../source/source.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';

/// Handle import statement in sources and bundle
/// all related sources into a single compilation
class HTBundler {
  final Map<String, HTParser> parsers = {};

  late HTParser _currentParser;

  final HTResourceContext<HTSource> sourceContext;

  HTBundler(
      {String parserName = 'default',
      HTParser? parser,
      HTResourceContext<HTSource>? sourceContext})
      : sourceContext = sourceContext ?? HTOverlayContext() {
    parsers[parserName] = _currentParser = parser ?? HTDefaultParser();
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  ASTCompilation bundle(HTSource entry) {
    final result = _currentParser.parseSource(entry);
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
          final currentDir =
              result.fullName.startsWith(InternalIdentifier.anonymousScript)
                  ? sourceContext.root
                  : path.dirname(result.fullName);
          final importFullName = sourceContext.getAbsolutePath(
              key: decl.fromPath!, dirName: currentDir);
          decl.fullName = importFullName;
          if (_cachedParsingTargets.contains(importFullName)) {
            continue;
          }
          // else if (_cachedParseResults.containsKey(importFullName)) {
          //   importedSource = _cachedParseResults[importFullName]!;
          // }
          else {
            final source2 = sourceContext.getResource(importFullName);
            importedSource = _currentParser.parseSource(source2);
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
              filename: entry.fullName,
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
        entryResourceName: entry.fullName,
        entryResourceType: entry.type,
        errors: parserErrors);
    return compilation;
  }
}
