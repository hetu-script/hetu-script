import 'dart:io';

import 'package:path/path.dart' as path;

import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../grammar/lexicon.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import 'parse_result.dart';
import 'parse_result_compilation.dart';
// import '../error/error_handler.dart';
import 'abstract_parser.dart';
import '../lexer/lexer.dart';

/// Walk through a token list and generates a abstract syntax tree.
class HTParser extends HTAbstractParser {
  static var anonymousFunctionIndex = 0;
  // static var anonymousStructIndex = 0;

  final _curModuleImports = <ImportExportDecl>[];

  String? _curModuleFullName;
  @override
  String? get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  @override
  String? get curLibraryName => _curLibraryName;

  HTClassDeclaration? _curClass;
  FunctionCategory? _curFuncCategory;
  String? _curStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasMetaInfo = false;

  bool _hasUserDefinedConstructor = false;

  HTSource? _curSource;

  final _cachedResults = <String, HTModuleParseResult>{};

  final Set<String> _cachedRecursiveParsingTargets = {};

  @override
  final HTResourceContext<HTSource> sourceContext;

  HTParser({HTResourceContext<HTSource>? context})
      : sourceContext = context ?? HTOverlayContext();

  /// Will use [type] when possible, then [source.kType], then [SourceType.module]
  List<AstNode> parse(List<Token> tokens,
      {HTSource? source, SourceType? type, ParserConfig? config}) {
    final nodes = <AstNode>[];
    _curSource = source;
    _curModuleFullName = source?.name;
    setTokens(tokens);
    while (curTok.type != SemanticNames.endOfFile) {
      if (curTok.type == SemanticNames.emptyLine) {
        advance(1);
        // final empty = advance(1);
        // final stmt = EmptyExpr(
        //     line: empty.line, column: empty.column, offset: empty.offset);
        // nodes.add(stmt);
      } else {
        late SourceType sourceType;
        if (type != null) {
          sourceType = type;
        } else {
          if (_curSource != null) {
            sourceType =
                _curSource!.isScript ? SourceType.script : SourceType.module;
          } else {
            sourceType = SourceType.module;
          }
        }
        final stmt = _parseStmt(sourceType: sourceType);
        // if (stmt != null) {
        nodes.add(stmt);
        // }
      }
    }
    if (nodes.isEmpty) {
      // tokens can not be empty, lexer will insert a empty line token anyway
      final empty = EmptyExpr(
          source: _curSource,
          line: tokens.first.line,
          column: tokens.first.column,
          offset: tokens.first.offset,
          length: tokens.last.end - tokens.first.offset);
      nodes.add(empty);
    }
    return nodes;
  }

  List<AstNode> parseString(String content, {HTSource? source}) {
    final tokens = HTLexer().lex(content);
    final nodes = parse(tokens, source: source);
    return nodes;
  }

  HTModuleParseResult parseToModule(HTSource source, {String? libraryName}) {
    _curLibraryName = libraryName ?? source.name;
    _curModuleFullName = source.name;
    _curClass = null;
    _curFuncCategory = null;
    final nodes = parseString(source.content, source: source);
    final module = HTModuleParseResult(source, nodes,
        hasMetaInfo: _hasMetaInfo,
        packageName: libraryName,
        imports: _curModuleImports.toList(),
        errors: errors); // copy the list);
    _curModuleImports.clear();
    return module;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  HTModuleParseResultCompilation parseToCompilation(HTSource source,
      {String? libraryName}) {
    final module = parseToModule(source, libraryName: libraryName);
    final results = <String, HTModuleParseResult>{};

    void handleImport(HTModuleParseResult module) {
      _cachedRecursiveParsingTargets.add(module.fullName);
      for (final decl in module.imports) {
        try {
          late final HTModuleParseResult importModule;
          final importFullName = sourceContext.getAbsolutePath(
              key: decl.fromPath!, dirName: path.dirname(module.fullName));
          decl.fullName = importFullName;
          if (_cachedRecursiveParsingTargets.contains(importFullName)) {
            continue;
          } else if (_cachedResults.containsKey(importFullName)) {
            importModule = _cachedResults[importFullName]!;
          } else {
            final source2 = sourceContext.getResource(importFullName);
            importModule = parseToModule(source2, libraryName: _curLibraryName);
            _cachedResults[importFullName] = importModule;
          }
          results[importFullName] = importModule;
          handleImport(importModule);
        } catch (error) {
          late HTError convertedError;
          if (error is FileSystemException) {
            convertedError = HTError.sourceProviderError(decl.fromPath!,
                moduleFullName: source.name,
                line: decl.line,
                column: decl.column,
                offset: decl.offset,
                length: decl.length);
          } else {
            convertedError = HTError.extern(error.toString(),
                moduleFullName: source.name,
                line: decl.line,
                column: decl.column,
                offset: decl.offset,
                length: decl.length);
          }
          module.errors.add(convertedError);
        }
      }
      _cachedRecursiveParsingTargets.remove(module.fullName);
    }

    handleImport(module);
    results[module.fullName] = module;
    final compilation = HTModuleParseResultCompilation(
        modules: results, isScript: source.isScript);
    return compilation;
  }

  AstNode _parseStmt({SourceType sourceType = SourceType.function}) {
    switch (sourceType) {
      case SourceType.script:
        if (curTok.lexeme == HTLexicon.kImport) {
          return _parseImportDecl();
        } else if (curTok.lexeme == HTLexicon.kExport) {
          return _parseExportStmt();
        } else if (curTok.lexeme == HTLexicon.kType) {
          return _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
              return _parseComment();
            case SemanticNames.multiLineComment:
              return _parseComment(isMultiline: true);
            case HTLexicon.kAssert:
              return _parseAssertStmt();
            case HTLexicon.kExternal:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.kAbstract:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true, isExternal: true, isTopLevel: true);
                case HTLexicon.kClass:
                  return _parseClassDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.kEnum:
                  return _parseEnumDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.kVar:
                case HTLexicon.kFinal:
                  final err = HTError.externalVar(
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  return EmptyExpr(
                      source: _curSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                case HTLexicon.kFun:
                  return _parseFunction(isExternal: true, isTopLevel: true);
                case HTLexicon.kAsync:
                  return _parseFunction(
                      isAsync: true, isExternal: true, isTopLevel: true);
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  return EmptyExpr(
                      source: _curSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
              }
            case HTLexicon.kAbstract:
              advance(1);
              return _parseClassDecl(isAbstract: true, isTopLevel: true);
            case HTLexicon.kEnum:
              return _parseEnumDecl(isTopLevel: true);
            case HTLexicon.kClass:
              return _parseClassDecl(isTopLevel: true);
            case HTLexicon.kVar:
              return _parseVarDecl(isMutable: true, isTopLevel: true);
            case HTLexicon.kFinal:
              return _parseVarDecl(isTopLevel: true);
            case HTLexicon.kFun:
              if (expect([HTLexicon.kFun, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFunction(isTopLevel: true);
              } else {
                return _parseFunction(
                    category: FunctionCategory.literal, isTopLevel: true);
              }
            case HTLexicon.kAsync:
              if (expect([HTLexicon.kAsync, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFunction(isAsync: true, isTopLevel: true);
              } else {
                return _parseFunction(
                    category: FunctionCategory.literal,
                    isAsync: true,
                    isTopLevel: true);
              }
            case HTLexicon.kStruct:
              return _parseStructDecl(isTopLevel: true, lateInitialize: false);
            case HTLexicon.kIf:
              return _parseIf();
            case HTLexicon.kWhile:
              return _parseWhileStmt();
            case HTLexicon.kDo:
              return _parseDoStmt();
            case HTLexicon.kFor:
              return _parseForStmt();
            case HTLexicon.kWhen:
              return _parseWhenStmt();
            default:
              return _parseExprStmt();
          }
        }
      case SourceType.module:
        if (curTok.lexeme == HTLexicon.library) {
          return _parseLibraryDecl();
        } else if (curTok.lexeme == HTLexicon.kImport) {
          return _parseImportDecl();
        } else if (curTok.lexeme == HTLexicon.kExport) {
          return _parseExportStmt();
        } else if (curTok.lexeme == HTLexicon.kType) {
          return _parseTypeAliasDecl(isTopLevel: true);
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
              return _parseComment();
            case SemanticNames.multiLineComment:
              return _parseComment(isMultiline: true);
            case HTLexicon.kAssert:
              return _parseAssertStmt();
            case HTLexicon.kExternal:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.kAbstract:
                  advance(1);
                  if (curTok.type != HTLexicon.kClass) {
                    final err = HTError.unexpected(
                        SemanticNames.classDeclaration, curTok.lexeme,
                        moduleFullName: _curModuleFullName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    final errToken = advance(1);
                    return EmptyExpr(
                        source: _curSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                  } else {
                    return _parseClassDecl(
                        isAbstract: true, isExternal: true, isTopLevel: true);
                  }
                case HTLexicon.kClass:
                  return _parseClassDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.kEnum:
                  return _parseEnumDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.kFun:
                  return _parseFunction(isExternal: true, isTopLevel: true);
                case HTLexicon.kVar:
                case HTLexicon.kFinal:
                  final err = HTError.externalVar(
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  return EmptyExpr(
                      source: _curSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  return EmptyExpr(
                      source: _curSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
              }
            case HTLexicon.kAbstract:
              advance(1);
              return _parseClassDecl(isAbstract: true, isTopLevel: true);
            case HTLexicon.kEnum:
              return _parseEnumDecl(isTopLevel: true);
            case HTLexicon.kClass:
              return _parseClassDecl(isTopLevel: true);
            case HTLexicon.kVar:
              return _parseVarDecl(
                  isMutable: true, isTopLevel: true, lateInitialize: true);
            case HTLexicon.kFinal:
              return _parseVarDecl(lateInitialize: true, isTopLevel: true);
            case HTLexicon.kFun:
              return _parseFunction(isTopLevel: true);
            case HTLexicon.kStruct:
              return _parseStructDecl(isTopLevel: true);
            default:
              final err = HTError.unexpected(
                  SemanticNames.declStmt, curTok.lexeme,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              return EmptyExpr(
                  source: _curSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
        }
      case SourceType.klass:
        final isOverrided = expect([HTLexicon.kOverride], consume: true);
        final isExternal = expect([HTLexicon.kExternal], consume: true) ||
            (_curClass?.isExternal ?? false);
        final isStatic = expect([HTLexicon.kStatic], consume: true);
        if (curTok.lexeme == HTLexicon.kType) {
          if (isExternal) {
            final err = HTError.external(SemanticNames.typeAliasDeclaration,
                moduleFullName: _curModuleFullName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance(1);
            return EmptyExpr(
                source: _curSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            return _parseTypeAliasDecl();
          }
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
              return _parseComment();
            case SemanticNames.multiLineComment:
              return _parseComment(isMultiline: true);
            case HTLexicon.kVar:
              return _parseVarDecl(
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
            case HTLexicon.kFinal:
              return _parseVarDecl(
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
            case HTLexicon.kFun:
              return _parseFunction(
                  category: FunctionCategory.method,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.kAsync:
              if (isExternal) {
                final err = HTError.external(SemanticNames.asyncFunction,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                return _parseFunction(
                    category: FunctionCategory.method,
                    classId: _curClass?.id,
                    isAsync: true,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
              }
            case HTLexicon.kGet:
              return _parseFunction(
                  category: FunctionCategory.getter,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.kSet:
              return _parseFunction(
                  category: FunctionCategory.setter,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.kConstruct:
              if (isStatic) {
                final err = HTError.unexpected(
                    SemanticNames.declStmt, HTLexicon.kConstruct,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal && !_curClass!.isExternal) {
                final err = HTError.external(SemanticNames.ctorFunction,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                return _parseFunction(
                  category: FunctionCategory.constructor,
                  classId: _curClass?.id,
                  isExternal: isExternal,
                );
              }
            case HTLexicon.kFactory:
              if (isStatic) {
                final err = HTError.unexpected(
                    SemanticNames.declStmt, HTLexicon.kConstruct,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal && !_curClass!.isExternal) {
                final err = HTError.external(SemanticNames.factory,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                return _parseFunction(
                  category: FunctionCategory.factoryConstructor,
                  classId: _curClass?.id,
                  isExternal: isExternal,
                  isStatic: true,
                );
              }
            default:
              final err = HTError.unexpected(
                  SemanticNames.declStmt, curTok.lexeme,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              return EmptyExpr(
                  source: _curSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
        }
      case SourceType.struct:
        final isExternal = expect([HTLexicon.kExternal], consume: true);
        final isStatic = expect([HTLexicon.kStatic], consume: true);
        switch (curTok.type) {
          case SemanticNames.singleLineComment:
            return _parseComment();
          case SemanticNames.multiLineComment:
            return _parseComment(isMultiline: true);
          case HTLexicon.kVar:
            return _parseVarDecl(
                classId: _curStructId,
                isExternal: isExternal,
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.kFinal:
            return _parseVarDecl(
                classId: _curStructId,
                isExternal: isExternal,
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.kFun:
            return _parseFunction(
                category: FunctionCategory.method,
                classId: _curStructId,
                isExternal: isExternal,
                isField: true,
                isStatic: isStatic);
          case HTLexicon.kAsync:
            if (isExternal) {
              final err = HTError.external(SemanticNames.asyncFunction,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              return EmptyExpr(
                  source: _curSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              return _parseFunction(
                  category: FunctionCategory.method,
                  classId: _curStructId,
                  isAsync: true,
                  isExternal: isExternal,
                  isField: true,
                  isStatic: isStatic);
            }
          case HTLexicon.kGet:
            return _parseFunction(
                category: FunctionCategory.getter,
                classId: _curStructId,
                isExternal: isExternal,
                isField: true,
                isStatic: isStatic);
          case HTLexicon.kSet:
            return _parseFunction(
                category: FunctionCategory.setter,
                classId: _curStructId,
                isExternal: isExternal,
                isField: true,
                isStatic: isStatic);
          case HTLexicon.kConstruct:
            if (isStatic) {
              final err = HTError.unexpected(
                  SemanticNames.declStmt, HTLexicon.kConstruct,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              return EmptyExpr(
                  source: _curSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal) {
              final err = HTError.external(SemanticNames.ctorFunction,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              return EmptyExpr(
                  source: _curSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              return _parseFunction(
                  category: FunctionCategory.constructor,
                  classId: _curStructId,
                  isExternal: isExternal,
                  isField: true);
            }
          default:
            final err = HTError.unexpected(
                SemanticNames.declStmt, curTok.lexeme,
                moduleFullName: _curModuleFullName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance(1);
            return EmptyExpr(
                source: _curSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
        }
      case SourceType.function:
        if (curTok.lexeme == HTLexicon.kType) {
          return _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
              return _parseComment();
            case SemanticNames.multiLineComment:
              return _parseComment(isMultiline: true);
            case HTLexicon.kAssert:
              return _parseAssertStmt();
            case HTLexicon.kAbstract:
              advance(1);
              return _parseClassDecl(isAbstract: true);
            case HTLexicon.kEnum:
              return _parseEnumDecl();
            case HTLexicon.kClass:
              return _parseClassDecl();
            case HTLexicon.kVar:
              return _parseVarDecl(isMutable: true);
            case HTLexicon.kFinal:
              return _parseVarDecl();
            case HTLexicon.kFun:
              if (expect([HTLexicon.kFun, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFunction();
              } else {
                return _parseFunction(category: FunctionCategory.literal);
              }
            case HTLexicon.kAsync:
              if (expect([HTLexicon.kAsync, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFunction(isAsync: true);
              } else {
                return _parseFunction(
                    category: FunctionCategory.literal, isAsync: true);
              }
            case HTLexicon.kStruct:
              return _parseStructDecl(lateInitialize: false);
            case HTLexicon.kIf:
              return _parseIf();
            case HTLexicon.kWhile:
              return _parseWhileStmt();
            case HTLexicon.kDo:
              return _parseDoStmt();
            case HTLexicon.kFor:
              return _parseForStmt();
            case HTLexicon.kWhen:
              return _parseWhenStmt();
            case HTLexicon.kBreak:
              final keyword = advance(1);
              return BreakStmt(keyword,
                  source: _curSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
            case HTLexicon.kContinue:
              final keyword = advance(1);
              return ContinueStmt(keyword,
                  source: _curSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
            case HTLexicon.kReturn:
              if (_curFuncCategory != null &&
                  _curFuncCategory != FunctionCategory.constructor) {
                return _parseReturnStmt();
              } else {
                final err = HTError.outsideReturn(
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                return EmptyExpr(
                    source: _curSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              }
            default:
              return _parseExprStmt();
          }
        }
      case SourceType.expression:
        return _parseExpr();
    }
  }

  CommentExpr _parseComment({bool isMultiline = false}) {
    if (!isMultiline) {
      final comment = match(SemanticNames.singleLineComment);
      return CommentExpr(comment.literal,
          isMultiline: false,
          isDocumentation: comment.lexeme
              .startsWith(HTLexicon.singleLineCommentDocumentationPattern),
          source: _curSource,
          line: comment.line,
          column: comment.column,
          offset: comment.offset,
          length: comment.length);
    } else {
      final comment = match(SemanticNames.multiLineComment);
      return CommentExpr(comment.literal,
          isMultiline: true,
          isDocumentation: comment.lexeme
              .startsWith(HTLexicon.multiLineCommentDocumentationPattern),
          source: _curSource,
          line: comment.line,
          column: comment.column,
          offset: comment.offset,
          length: comment.length);
    }
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(HTLexicon.kAssert);
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = AssertStmt(expr,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        final err = HTError.invalidLeftValue(
            moduleFullName: _curModuleFullName,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: left.length);
        errors.add(err);
      }
      final op = advance(1);
      final right = _parseExpr();
      if (op.type == HTLexicon.assign) {
        if (left is MemberExpr) {
          return MemberAssignExpr(left.object, left.key, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          return SubAssignExpr(left.object, left.key, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          return BinaryExpr(left, op.lexeme, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      } else {
        if (left is MemberExpr) {
          return MemberAssignExpr(left.object, left.key,
              BinaryExpr(left, op.lexeme.substring(0, 1), right),
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          return SubAssignExpr(left.object, left.key,
              BinaryExpr(left, op.lexeme.substring(0, 1), right),
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          return BinaryExpr(left, op.lexeme.substring(1),
              BinaryExpr(left, op.lexeme.substring(0, 1), right),
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      }
    } else {
      return left;
    }
  }

  AstNode _parserTernaryExpr() {
    var condition = _parseLogicalOrExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: _curSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// 逻辑或 || , 优先级 5, 左合并
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1); // and operator
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 逻辑和 && , 优先级 6, 左合并
  AstNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        final op = advance(1); // and operator
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 逻辑相等 ==, !=, 优先级 7, 不合并
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// 逻辑比较 <, >, <=, >=, as, is, is! 优先级 8, 不合并
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      late final String opLexeme;
      if (op.lexeme == HTLexicon.kIs) {
        opLexeme = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.kIsNot
            : HTLexicon.kIs;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// 加法 +, -, 优先级 13, 左合并
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 乘法 *, /, %, 优先级 14, 左合并
  AstNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15, 不合并
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance(1);
      final value = _parseUnaryPostfixExpr();
      return UnaryPrefixExpr(op.lexeme, value,
          source: _curSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// 后缀 e., e[], e(), e++, e-- 优先级 16, 右合并
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance(1);
      switch (op.type) {
        case HTLexicon.memberGet:
          _leftValueLegality = true;
          final name = match(SemanticNames.identifier);
          final key = IdentifierExpr(name.lexeme,
              isLocal: false,
              source: _curSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          expr = SubExpr(expr, indexExpr,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.call:
          // TODO: typeArgs: typeArgs
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr, positionalArgs, namedArgs,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op.lexeme,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        default:
          break;
      }
    }
    return expr;
  }

  /// Expression without operators
  AstNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.kNull:
        _leftValueLegality = false;
        final token = advance(1);
        return NullExpr(
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.booleanLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenBooleanLiteral;
        return BooleanExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.integerLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenIntLiteral;
        return ConstIntExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.floatLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenFloatLiteral;
        return ConstFloatExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringLiteral;
        return ConstStringExpr(
            token.literal, token.quotationLeft, token.quotationRight,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringInterpolation:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringInterpolation;
        final interpolation = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTParser(context: sourceContext);
          final nodes = exprParser.parse(tokens,
              source: _curSource, type: SourceType.expression);
          errors.addAll(exprParser.errors);
          if (nodes.length > 1) {
            final err = HTError.stringInterpolation(
                moduleFullName: _curModuleFullName,
                line: nodes.first.line,
                column: nodes.first.column,
                offset: nodes.first.offset,
                length: nodes.last.end - nodes.first.offset);
            errors.add(err);
            final errNode = EmptyExpr(
                source: _curSource,
                line: token.line,
                column: token.column,
                offset: token.offset);
            interpolation.add(errNode);
          } else {
            // parser will at least insert a empty line astnode
            if (nodes.first is EmptyExpr) {
              final err = HTError.stringInterpolation(
                  moduleFullName: _curModuleFullName,
                  line: nodes.first.line,
                  column: nodes.first.column,
                  offset: nodes.first.offset,
                  length: nodes.first.length +
                      HTLexicon.stringInterpolationStart.length +
                      HTLexicon.stringInterpolationEnd.length);
              errors.add(err);
            }
            interpolation.add(nodes.first);
          }
        }
        var i = 0;
        final value = token.literal.replaceAllMapped(
            RegExp(HTLexicon.stringInterpolationPattern),
            (Match m) => '${HTLexicon.curlyLeft}${i++}${HTLexicon.curlyRight}');
        return StringInterpolationExpr(
            value, token.quotationLeft, token.quotationRight, interpolation,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case HTLexicon.kThis:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _curSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kSuper:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _curSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kIf:
        final expr = _parseIf(isExpression: true);
        return expr;
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        // a literal function expression
        final token = seek(HTLexicon.roundRight);
        if (token.type == HTLexicon.curlyLeft ||
            token.type == HTLexicon.doubleArrow) {
          return _parseFunction(
              category: FunctionCategory.literal, hasKeyword: false);
        }
        // a group expression
        else {
          final start = advance(1);
          final innerExpr = _parseExpr();
          final end = match(HTLexicon.roundRight);
          return GroupExpr(innerExpr,
              source: _curSource,
              line: start.line,
              column: start.column,
              offset: start.offset,
              length: end.offset + end.length - start.offset);
        }
      case HTLexicon.squareLeft:
        _leftValueLegality = false;
        final start = advance(1);
        var listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.squareRight &&
            curTok.type != SemanticNames.endOfFile) {
          AstNode item;
          if (curTok.type == HTLexicon.spreadSyntax) {
            final spreadTok = advance(1);
            item = _parseExpr();
            listExpr.add(SpreadExpr(item,
                source: _curSource,
                line: spreadTok.line,
                column: spreadTok.column,
                offset: spreadTok.offset,
                length: item.end - spreadTok.offset));
          } else {
            item = _parseExpr();
            listExpr.add(item);
          }
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        final end = match(HTLexicon.squareRight);
        return ListExpr(listExpr,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.end - start.offset);
      case HTLexicon.curlyLeft:
        return _parseStructObj();
      case HTLexicon.kStruct:
        return _parseStructObj(hasKeyword: true);
      // _leftValueLegality = false;
      // final start = advance(1);
      // var mapExpr = <AstNode, AstNode>{};
      // while (curTok.type != HTLexicon.curlyRight) {
      //   var keyExpr = _parseExpr();
      //   match(HTLexicon.colon);
      //   var valueExpr = _parseExpr();
      //   mapExpr[keyExpr] = valueExpr;
      //   if (curTok.type != HTLexicon.curlyRight) {
      //     match(HTLexicon.comma);
      //   }
      // }
      // final end = match(HTLexicon.curlyRight);
      // return MapExpr(mapExpr,
      //     source: _curSource,
      //     line: start.line,
      //     column: start.column,
      //     offset: start.offset,
      //     length: end.offset + end.length - start.offset);
      case HTLexicon.kFun:
        return _parseFunction(category: FunctionCategory.literal);
      case SemanticNames.identifier:
        // literal function type
        if (curTok.lexeme == HTLexicon.kFun) {
          _leftValueLegality = false;
          return _parseTypeExpr();
        }
        // TODO: literal interface type
        else {
          _leftValueLegality = true;
          final id = advance(1);
          // TODO: type arguments
          return IdentifierExpr.fromToken(id);
        }
      default:
        final err = HTError.unexpected(SemanticNames.expression, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
        final errToken = advance(1);
        return EmptyExpr(
            source: _curSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == HTLexicon.roundLeft) {
      final startTok = match(HTLexicon.roundLeft);
      // TODO: genericTypeParameters 泛型参数
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != HTLexicon.roundRight &&
          curTok.type != SemanticNames.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(SemanticNames.identifier);
          paramSymbol = IdentifierExpr.fromToken(paramId);
          match(HTLexicon.colon);
        }
        paramType = _parseTypeExpr();
        final param = ParamTypeExpr(paramType,
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramSymbol,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: curTok.offset - start.offset);
        parameters.add(param);
        if (isOptional && expect([HTLexicon.squareRight], consume: true)) {
          break;
        } else if (isNamed && expect([HTLexicon.curlyRight], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }
        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.roundRight);
      match(HTLexicon.singleArrow);
      final returnType = _parseTypeExpr();
      return FuncTypeExpr(returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: _curSource,
          line: startTok.line,
          column: startTok.column,
          offset: startTok.offset,
          length: curTok.offset - startTok.offset);
    }
    // TODO: interface type
    // else if (curTok.type == HTLexicon.curlyLeft) {
    //   return StructuralTypeExpr();
    // }
    // nominal type
    else {
      final idTok = match(SemanticNames.identifier);
      final id = IdentifierExpr.fromToken(idTok);
      final typeArgs = <TypeExpr>[];
      if (expect([HTLexicon.angleLeft], consume: true)) {
        if (curTok.type == HTLexicon.angleRight) {
          final err = HTError.emptyTypeArgs(
              moduleFullName: _curModuleFullName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length + curTok.length);
          errors.add(err);
        }
        while ((curTok.type != HTLexicon.angleRight) &&
            (curTok.type != SemanticNames.endOfFile)) {
          typeArgs.add(_parseTypeExpr());
          expect([HTLexicon.comma], consume: true);
        }
        match(HTLexicon.angleRight);
      }
      final isNullable = expect([HTLexicon.nullable], consume: true);
      return TypeExpr(
        id: id,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        source: _curSource,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
      );
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      SourceType sourceType = SourceType.function,
      bool hasOwnNamespace = true}) {
    final start = match(HTLexicon.curlyLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      // if (stmt != null) {
      statements.add(stmt);
      // }
    }
    match(HTLexicon.curlyRight);
    return BlockStmt(statements,
        id: id,
        hasOwnNamespace: hasOwnNamespace,
        source: _curSource,
        line: start.line,
        column: start.column,
        offset: start.offset,
        length: curTok.offset - start.offset);
  }

  void _handleCallArguments(
      List<AstNode> positionalArgs, Map<String, AstNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != SemanticNames.endOfFile)) {
      if ((!isNamed &&
              expect([SemanticNames.identifier, HTLexicon.colon],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.colon);
        final value = _parseExpr();
        namedArgs[name] = value;
      } else {
        if (curTok.type == HTLexicon.spreadSyntax) {
          final spreadTok = advance(1);
          final arg = _parseExpr();
          positionalArgs.add(SpreadExpr(arg,
              source: _curSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: arg.end - spreadTok.offset));
        } else {
          final arg = _parseExpr();
          positionalArgs.add(arg);
        }
      }
      if (curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }
    }
    match(HTLexicon.roundRight);
  }

  AstNode _parseExprStmt() {
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = ExprStmt(expr,
        source: _curSource,
        line: expr.line,
        column: expr.column,
        offset: expr.offset,
        length: curTok.offset - expr.offset);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.semicolon &&
        curTok.type != SemanticNames.endOfFile) {
      expr = _parseExpr();
    }
    expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword, expr,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == HTLexicon.curlyLeft) {
      return _parseBlockStmt(id: SemanticNames.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        // final token = curTok;
        final node = _parseStmt();
        // if (node == null) {
        //   final err = HTError.unexpected(
        //       SemanticNames.statement, SemanticNames.emptyLine,
        //       moduleFullName: curModuleFullName,
        //       line: curTok.line,
        //       column: curTok.column);
        //   errors.add(err);
        //   return EmptyExpr(
        //       source: _curSource,
        //       line: token.line,
        //       column: token.column,
        //       offset: token.offset);
        // } else {
        return node;
        // }
      }
    }
  }

  IfStmt _parseIf({bool isExpression = false}) {
    final keyword = match(HTLexicon.kIf);
    match(HTLexicon.roundLeft);
    final condition = _parseExpr();
    match(HTLexicon.roundRight);
    final thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    AstNode? elseBranch;
    if (isExpression) {
      match(HTLexicon.kElse);
      elseBranch = _parseExpr();
    } else {
      if (expect([HTLexicon.kElse], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(HTLexicon.kWhile);
    match(HTLexicon.roundLeft);
    final condition = _parseExpr();
    match(HTLexicon.roundRight);
    final loop = _parseBlockStmt(id: SemanticNames.whileLoop);
    return WhileStmt(condition, loop,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    final loop = _parseBlockStmt(id: SemanticNames.doLoop);
    AstNode? condition;
    if (expect([HTLexicon.kWhile], consume: true)) {
      match(HTLexicon.roundLeft);
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    return DoStmt(loop, condition,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseForStmt() {
    final keyword = advance(1);
    final hasBracket = expect([HTLexicon.roundLeft], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.kIn || forStmtType == HTLexicon.kOf) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            SemanticNames.variableDeclaration, curTok.type,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.kFinal);
      advance(1);
      final collection = _parseExpr();
      if (hasBracket) {
        match(HTLexicon.roundRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == HTLexicon.kOf,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(HTLexicon.semicolon);
      }
      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);
      if (!expect([HTLexicon.roundRight], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(HTLexicon.roundRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhenStmt() {
    final keyword = advance(1);
    AstNode? condition;
    if (curTok.type != HTLexicon.curlyLeft) {
      match(HTLexicon.roundLeft);
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    final options = <AstNode, AstNode>{};
    AstNode? elseBranch;
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      if (curTok.lexeme == HTLexicon.kElse) {
        advance(1);
        match(HTLexicon.singleArrow);
        if (curTok.type == HTLexicon.curlyLeft) {
          elseBranch = _parseBlockStmt(id: SemanticNames.elseBranch);
        } else {
          final stmt = _parseStmt();
          // if (stmt == null) {
          //   final err = HTError.unexpected(
          //       SemanticNames.statement, SemanticNames.emptyLine,
          //       moduleFullName: curModuleFullName,
          //       line: curTok.line,
          //       column: curTok.column);
          //   errors.add(err);
          // }
          elseBranch = stmt;
        }
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        late final AstNode caseBranch;
        if (curTok.type == HTLexicon.curlyLeft) {
          caseBranch = _parseBlockStmt(id: SemanticNames.whenBranch);
        } else {
          final stmt = _parseStmt();
          // if (stmt == null) {
          //   final err = HTError.unexpected(
          //       SemanticNames.statement, SemanticNames.emptyLine,
          //       moduleFullName: curModuleFullName,
          //       line: curTok.line,
          //       column: curTok.column);
          //   errors.add(err);
          // }
          caseBranch = stmt;
        }
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.curlyRight);
    return WhenStmt(options, elseBranch, condition,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    final genericParams = <GenericTypeParameterExpr>[];
    if (expect([HTLexicon.angleLeft], consume: true)) {
      while ((curTok.type != HTLexicon.angleRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        if (genericParams.isNotEmpty) {
          match(HTLexicon.comma);
        }
        final idTok = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(idTok);
        final param = GenericTypeParameterExpr(id,
            source: _curSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        genericParams.add(param);
      }
      match(HTLexicon.angleRight);
    }
    return genericParams;
  }

  LibraryDecl _parseLibraryDecl() {
    if (_hasMetaInfo) {
      final err = HTError.duplicateLibStmt(
          moduleFullName: _curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    }
    final keyword = advance(1);
    _hasMetaInfo = true;
    final id = match(SemanticNames.stringLiteral);
    final stmt = LibraryDecl(id.literal,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(1); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == HTLexicon.curlyLeft) {
      advance(1);
      do {
        final idTok = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(idTok);
        showList.add(id);
      } while (expect([HTLexicon.comma], consume: true));
      match(HTLexicon.curlyRight);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance(1).lexeme;
      if (fromKeyword != HTLexicon.kFrom) {
        final err = HTError.unexpected(HTLexicon.kFrom, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
    }
    final key = match(SemanticNames.stringLiteral);
    IdentifierExpr? alias;
    if (expect([HTLexicon.kAs], consume: true)) {
      final aliasId = match(SemanticNames.identifier);
      alias = IdentifierExpr.fromToken(aliasId);
    }
    final stmt = ImportExportDecl(
        fromPath: key.literal,
        alias: alias,
        showList: showList,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _curModuleImports.add(stmt);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(1); // not a keyword so don't use match
    if (curTok.type == HTLexicon.curlyLeft) {
      match(HTLexicon.curlyLeft);
      final showList = <IdentifierExpr>[];
      do {
        final curId = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(curId);
        showList.add(id);
      } while (expect([HTLexicon.comma], consume: true));
      match(HTLexicon.curlyRight);
      String? fromPath;
      if (curTok.lexeme == HTLexicon.kFrom) {
        advance(1);
        fromPath = match(SemanticNames.stringLiteral).literal;
      }
      final stmt = ImportExportDecl(
          showList: showList,
          fromPath: fromPath,
          isExported: true,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        _curModuleImports.add(stmt);
      }
      return stmt;
    } else {
      final key = match(SemanticNames.stringLiteral);
      final stmt = ImportExportDecl(
          fromPath: key.literal,
          isExported: true,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      _curModuleImports.add(stmt);
      return stmt;
    }
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isTopLevel = false}) {
    final keyword = advance(1);
    final idTok = match(SemanticNames.identifier);
    final id = IdentifierExpr.fromToken(idTok);
    final genericParameters = _getGenericParams();
    match(HTLexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(id, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isTopLevel: isTopLevel,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    if (isField) {
      final idTok = advance(1);
      late IdentifierExpr id;
      if (idTok.type == SemanticNames.identifier ||
          idTok.type == SemanticNames.stringLiteral) {
        id = IdentifierExpr.fromToken(idTok);
      } else {
        final err = HTError.structMemberId(
            moduleFullName: _curModuleFullName,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: idTok.length);
        errors.add(err);
      }
      match(HTLexicon.colon);
      final initializer = _parseExpr();
      return VarDecl(id,
          classId: classId,
          initializer: initializer,
          isMutable: isMutable,
          lateInitialize: lateInitialize,
          source: _curSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset);
    } else {
      final keyword = advance(1);
      final idTok = match(SemanticNames.identifier);
      final id = IdentifierExpr.fromToken(idTok);
      String? internalName;
      if (classId != null && isExternal) {
        if (!(_curClass!.isExternal) && !isStatic) {
          final err = HTError.externalMember(
              moduleFullName: _curModuleFullName,
              line: keyword.line,
              column: keyword.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
        }
        internalName = '$classId.${idTok.lexeme}';
      }
      TypeExpr? declType;
      if (expect([HTLexicon.colon], consume: true)) {
        declType = _parseTypeExpr();
      }
      var initializer = additionalInitializer;
      if (expect([HTLexicon.assign], consume: true)) {
        initializer = _parseExpr();
      }
      if (hasEndOfStatement) {
        match(HTLexicon.semicolon);
      } else {
        expect([HTLexicon.semicolon], consume: true);
      }
      return VarDecl(id,
          internalName: internalName,
          classId: classId,
          declType: declType,
          initializer: initializer,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isMutable: isMutable,
          isTopLevel: isTopLevel,
          lateInitialize: lateInitialize,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  FuncDecl _parseFunction(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool hasKeyword = true,
      bool isAsync = false,
      bool isField = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false}) {
    final savedCurFuncType = _curFuncCategory;
    _curFuncCategory = category;
    late Token startTok;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance(1);
    }
    String? externalTypedef;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([HTLexicon.squareLeft], consume: true)) {
        final err = HTError.internalFuncWithExternalTypeDef(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
        externalTypedef = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.squareRight);
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == SemanticNames.identifier) {
          id = advance(1);
        }
        internalName = (id == null)
            ? SemanticNames.constructor
            : '${SemanticNames.constructor}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == SemanticNames.identifier) {
          id = advance(1);
        }
        internalName = (id == null)
            ? '${SemanticNames.anonymousFunction}${HTParser.anonymousFunctionIndex++}'
            : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(SemanticNames.identifier);
        internalName = '${SemanticNames.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(SemanticNames.identifier);
        internalName = '${SemanticNames.setter}$id';
        break;
      default:
        id = match(SemanticNames.identifier);
        internalName = id.lexeme;
    }
    final genericParameters = _getGenericParams();
    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDecl>[];
    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.roundRight) &&
          (curTok.type != HTLexicon.squareRight) &&
          (curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        }
        if (!isNamed && !isVariadic) {
          if (!isOptional) {
            ++minArity;
            ++maxArity;
          } else {
            ++maxArity;
          }
        }
        final paramId = match(SemanticNames.identifier);
        final paramSymbol = IdentifierExpr.fromToken(paramId);
        TypeExpr? paramDeclType;
        if (expect([HTLexicon.colon], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }
        AstNode? initializer;
        if (expect([HTLexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                moduleFullName: _curModuleFullName,
                line: lastTok.line,
                column: lastTok.column,
                offset: lastTok.offset,
                length: lastTok.length);
            errors.add(err);
          }
        }
        final param = ParamDecl(paramSymbol,
            declType: paramDeclType,
            initializer: initializer,
            isVariadic: isVariadic,
            isOptional: isOptional,
            isNamed: isNamed,
            source: _curSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);

        paramDecls.add(param);
        if (curTok.type != HTLexicon.squareRight &&
            curTok.type != HTLexicon.curlyRight &&
            curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(HTLexicon.squareRight);
      } else if (isNamed) {
        match(HTLexicon.curlyRight);
      }

      final endTok = match(HTLexicon.roundRight);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            moduleFullName: _curModuleFullName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors.add(err);
      }
    }
    TypeExpr? returnType;
    RedirectingConstructorCallExpr? referCtor;
    // the return value type declaration
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            SemanticNames.functionDefinition, SemanticNames.returnType,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.nonCotrWithReferCtor(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      final ctorCallee = advance(1);
      if (!HTLexicon.constructorCall.contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(
            SemanticNames.ctorCallExpr, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors.add(err);
      }
      Token? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(SemanticNames.identifier);
        match(HTLexicon.roundLeft);
      } else {
        match(HTLexicon.roundLeft);
      }
      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee), positionalArgs, namedArgs,
          key: ctorKey != null ? IdentifierExpr.fromToken(ctorKey) : null,
          source: _curSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    AstNode? definition;
    if (curTok.type == HTLexicon.curlyLeft) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: SemanticNames.functionCall);
    } else if (expect([HTLexicon.doubleArrow], consume: true)) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExprStmt();
    } else if (expect([HTLexicon.assign], consume: true)) {
      final err = HTError.unsupported(
          SemanticNames.redirectingFunctionDefinition,
          moduleFullName: _curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_curClass?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([HTLexicon.semicolon], consume: true);
      }
    }
    _curFuncCategory = savedCurFuncType;
    return FuncDecl(internalName, paramDecls,
        id: id != null ? IdentifierExpr.fromToken(id) : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        returnType: returnType,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        minArity: minArity,
        maxArity: maxArity,
        definition: definition,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isTopLevel: isTopLevel,
        category: category,
        source: _curSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  ClassDecl _parseClassDecl(
      {String? classId,
      bool isExternal = false,
      bool isAbstract = false,
      bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kClass);
    if (_curClass != null && _curClass!.isNested) {
      final err = HTError.nestedClass(
          moduleFullName: _curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors.add(err);
    }
    final id = match(SemanticNames.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (expect([HTLexicon.kExtends], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      superClassType = _parseTypeExpr();
    }
    final savedClass = _curClass;
    _curClass = HTClassDeclaration(
        id: id.lexeme,
        classId: classId,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: SourceType.klass,
        hasOwnNamespace: false,
        id: SemanticNames.classDefinition);
    final decl = ClassDecl(IdentifierExpr.fromToken(id), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _curClass = savedClass;
    return decl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kEnum);
    final id = match(SemanticNames.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != SemanticNames.endOfFile) {
        final enumIdTok = match(SemanticNames.identifier);
        final enumId = IdentifierExpr.fromToken(enumIdTok);
        enumerations.add(enumId);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }
    return EnumDecl(IdentifierExpr.fromToken(id), enumerations,
        isExternal: isExternal,
        isTopLevel: isTopLevel,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructDecl _parseStructDecl(
      {bool isTopLevel = false, bool lateInitialize = true}) {
    final keyword = match(HTLexicon.kStruct);
    final idTok = match(SemanticNames.identifier);
    final id = IdentifierExpr.fromToken(idTok);
    IdentifierExpr? prototypeId;
    if (expect([HTLexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(SemanticNames.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            moduleFullName: _curModuleFullName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors.add(err);
      }
      prototypeId = IdentifierExpr.fromToken(prototypeIdTok);
    } else if (id.id != HTLexicon.prototype) {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    final savedStructId = _curStructId;
    _curStructId = id.id;
    final definition = <AstNode>[];
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      final stmt = _parseStmt(sourceType: SourceType.struct);
      // if (stmt != null) {
      definition.add(stmt);
      // }
    }
    match(HTLexicon.curlyRight);
    _curStructId = savedStructId;
    return StructDecl(id, definition,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        lateInitialize: lateInitialize,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(HTLexicon.kStruct);
      if (hasKeyword && expect([HTLexicon.kExtends], consume: true)) {
        final idTok = match(SemanticNames.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok);
      }
    } else {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    // final internalName =
    //     '${SemanticNames.anonymousStruct}${HTParser.anonymousStructIndex++}';
    final structBlockStartTok = match(HTLexicon.curlyLeft);
    final fields = <StructObjField>[];
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      if (curTok.type == SemanticNames.identifier ||
          curTok.type == SemanticNames.stringLiteral) {
        final keyTok = advance(1);
        late final StructObjField field;
        if (curTok.type == HTLexicon.comma ||
            curTok.type == HTLexicon.curlyRight) {
          final id = IdentifierExpr.fromToken(keyTok);
          field = StructObjField(id, key: keyTok.lexeme);
        } else {
          match(HTLexicon.colon);
          final value = _parseExpr();
          field = StructObjField(value, key: keyTok.lexeme);
        }
        fields.add(field);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      } else if (curTok.type == HTLexicon.spreadSyntax) {
        match(HTLexicon.spreadSyntax);
        final value = _parseExpr();
        final field = StructObjField(value, isSpread: true);
        fields.add(field);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      } else if (curTok.type == SemanticNames.singleLineComment ||
          curTok.type == SemanticNames.multiLineComment) {
        final comment = _parseComment();
        final field = StructObjField(comment, isComment: true);
        fields.add(field);
      } else {
        final errTok = advance(1);
        final err = HTError.structMemberId(
            moduleFullName: _curModuleFullName,
            line: errTok.line,
            column: errTok.column,
            offset: errTok.offset,
            length: errTok.length);
        errors.add(err);
      }
    }
    match(HTLexicon.curlyRight);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: _curSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
