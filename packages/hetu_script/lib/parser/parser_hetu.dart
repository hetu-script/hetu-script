import 'package:path/path.dart' as path;

import 'parser.dart';
import 'token.dart';
import '../error/error.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/function/function_declaration.dart';
import '../ast/ast.dart';
import '../version.dart';
import '../locale/locale.dart';
import '../common/function_category.dart';
import '../common/internal_identifier.dart';

/// Default parser implementation used by Hetu.
class HTParserHetu extends HTParser {
  @override
  String get name => 'default';

  HTParserHetu({
    super.config,
  });

  bool get _isWithinModuleNamespace {
    if (_currentFunctionDeclaration != null) {
      return false;
    }

    if (currentSource?.type == HTResourceType.hetuModule) {
      return true;
    }

    return false;
  }

  // String? _currentExplicitNamespaceId;
  HTClassDeclaration? _currentClassDeclaration;
  HTFunctionDeclaration? _currentFunctionDeclaration;
  String? _currentStructId;
  bool _isLegalLeftValue = false;
  bool _hasUserDefinedConstructor = false;
  bool _isInLoop = false;

  @override
  void resetFlags() {
    _currentClassDeclaration = null;
    _currentFunctionDeclaration = null;
    _currentStructId = null;
    _isLegalLeftValue = false;
    _hasUserDefinedConstructor = false;
    _isInLoop = false;
  }

  @override
  ASTNode? parseStmt({required ParseStyle style}) {
    handlePrecedings();

    // handle emtpy statement.
    if (curTok.lexeme == lexer.lexicon.endOfStatementMark) {
      advance();
      return null;
    }

    if (curTok.lexeme == Token.endOfFile) {
      return null;
    }

    // save preceding comments because those might change during expression parsing.
    final savedPrecedings = savePrecedings();

    ASTNode stmt;

    switch (style) {
      case ParseStyle.script:
        if (curTok.lexeme == lexer.lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexer.lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexer.lexicon.kTypeDef) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kNamespace) {
          stmt = _parseNamespaceDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kAssert) {
          stmt = _parseAssertStmt();
        } else if (curTok.lexeme == lexer.lexicon.kExternal) {
          advance();
          if (curTok.lexeme == lexer.lexicon.kAbstract) {
            advance();
            stmt = _parseClassDecl(
                isAbstract: true, isExternal: true, isTopLevel: true);
          } else if (curTok.lexeme == lexer.lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.lexeme == lexer.lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
          } else if (lexer.lexicon.variableDeclarationKeywords
              .contains(curTok.lexeme)) {
            final err = HTError.externalVar(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else if (curTok.lexeme == lexer.lexicon.kAsync) {
            advance();
            stmt = _parseFunction(
                isAsync: true, isExternal: true, isTopLevel: true);
          } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
            stmt = _parseFunction(isExternal: true, isTopLevel: true);
          } else {
            final err = HTError.unexpected(lexer.lexicon.kExternal,
                HTLocale.current.declarationStatement, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        } else if (curTok.lexeme == lexer.lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(
              isAbstract: true, isTopLevel: true, lateResolve: false);
        } else if (curTok.lexeme == lexer.lexicon.kClass) {
          stmt = _parseClassDecl(isTopLevel: true, lateResolve: false);
        } else if (curTok.lexeme == lexer.lexicon.kEnum) {
          stmt = _parseEnumDecl(isTopLevel: true);
        } else if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl(isTopLevel: true, isMutable: true);
          } else {
            stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
          }
        } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl(isTopLevel: true);
          } else {
            stmt = _parseVarDecl(isTopLevel: true);
          }
        } else if (curTok.lexeme == lexer.lexicon.kConst) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl(isTopLevel: true);
          } else {
            stmt = _parseVarDecl(
              // isConst: true,
              isTopLevel: true,
            );
          }
        } else if (curTok.lexeme == lexer.lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kAsync) {
          advance();
          stmt = _parseFunction(isAsync: true, isTopLevel: true);
        } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          stmt = _parseFunction(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kStruct) {
          stmt =
              _parseStructDecl(isTopLevel: true); // , lateInitialize: false);
        } else if (curTok.lexeme == lexer.lexicon.kDelete) {
          stmt = _parseDeleteStmt();
        } else if (curTok.lexeme == lexer.lexicon.kIf) {
          stmt = _parseIf();
        } else if (curTok.lexeme == lexer.lexicon.kWhile) {
          stmt = _parseWhileStmt();
        } else if (curTok.lexeme == lexer.lexicon.kDo) {
          stmt = _parseDoStmt();
        } else if (curTok.lexeme == lexer.lexicon.kFor) {
          stmt = _parseForStmt();
        } else if (lexer.lexicon.kSwitchs.contains(curTok.lexeme)) {
          stmt = _parseSwitch();
        } else if (curTok.lexeme == lexer.lexicon.kThrow) {
          stmt = _parseThrowStmt();
        } else {
          stmt = _parseExprStmt();
        }
      case ParseStyle.module:
        if (curTok.lexeme == lexer.lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexer.lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexer.lexicon.kTypeDef) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kNamespace) {
          stmt = _parseNamespaceDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kExternal) {
          advance();
          if (curTok.lexeme == lexer.lexicon.kAbstract) {
            advance();
            if (curTok.lexeme != lexer.lexicon.kClass) {
              final err = HTError.unexpected(lexer.lexicon.kAbstract,
                  HTLocale.current.classDeclaration, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseClassDecl(
                  isAbstract: true, isExternal: true, isTopLevel: true);
            }
          } else if (curTok.lexeme == lexer.lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.lexeme == lexer.lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.lexeme == lexer.lexicon.kAsync) {
            advance();
            stmt = _parseFunction(
                isAsync: true, isExternal: true, isTopLevel: true);
          } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
            stmt = _parseFunction(isExternal: true, isTopLevel: true);
          } else if (lexer.lexicon.variableDeclarationKeywords
              .contains(curTok.lexeme)) {
            final err = HTError.externalVar(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            final err = HTError.unexpected(lexer.lexicon.kExternal,
                HTLocale.current.declarationStatement, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        } else if (curTok.lexeme == lexer.lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kClass) {
          stmt = _parseClassDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kEnum) {
          stmt = _parseEnumDecl(isTopLevel: true);
        } else if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
          stmt = _parseVarDecl(
              isMutable: true, isTopLevel: true, lateInitialize: true);
        } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
          stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kConst) {
          stmt = _parseVarDecl(
            lateInitialize: true,
            // isConst: true,
            isTopLevel: true,
          );
        } else if (curTok.lexeme == lexer.lexicon.kAsync) {
          advance();
          stmt = _parseFunction(isAsync: true, isTopLevel: true);
        } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          stmt = _parseFunction(isTopLevel: true);
        } else if (curTok.lexeme == lexer.lexicon.kStruct) {
          stmt = _parseStructDecl(isTopLevel: true);
        } else {
          final err = HTError.unexpected(HTLocale.current.module,
              HTLocale.current.declarationStatement, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
          final errToken = advance();
          stmt = ASTEmptyLine(
              source: currentSource,
              line: errToken.line,
              column: errToken.column,
              offset: errToken.offset);
        }
      case ParseStyle.namespace:
        if (curTok.lexeme == lexer.lexicon.kTypeDef) {
          stmt = _parseTypeAliasDecl();
        } else if (curTok.lexeme == lexer.lexicon.kNamespace) {
          stmt = _parseNamespaceDecl();
        } else if (curTok.lexeme == lexer.lexicon.kExternal) {
          advance();
          if (curTok.lexeme == lexer.lexicon.kAbstract) {
            advance();
            if (curTok.lexeme != lexer.lexicon.kClass) {
              final err = HTError.unexpected(lexer.lexicon.kAbstract,
                  HTLocale.current.classDeclaration, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseClassDecl(isAbstract: true, isExternal: true);
            }
          } else if (curTok.lexeme == lexer.lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true);
          } else if (curTok.lexeme == lexer.lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true);
          } else if (curTok.lexeme == lexer.lexicon.kAsync) {
            advance();
            stmt = _parseFunction(isAsync: true, isExternal: true);
          } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
            stmt = _parseFunction(isExternal: true);
          } else if (lexer.lexicon.variableDeclarationKeywords
              .contains(curTok.lexeme)) {
            final err = HTError.externalVar(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            final err = HTError.unexpected(lexer.lexicon.kExternal,
                HTLocale.current.declarationStatement, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        } else if (curTok.lexeme == lexer.lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(
              isAbstract: true, lateResolve: _isWithinModuleNamespace);
        } else if (curTok.lexeme == lexer.lexicon.kClass) {
          stmt = _parseClassDecl(lateResolve: _isWithinModuleNamespace);
        } else if (curTok.lexeme == lexer.lexicon.kEnum) {
          stmt = _parseEnumDecl();
        } else if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
          stmt = _parseVarDecl(
              isMutable: true, lateInitialize: _isWithinModuleNamespace);
        } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
          stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace);
        } else if (curTok.lexeme == lexer.lexicon.kConst) {
          stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace
              // isConst: true,
              );
        } else if (curTok.lexeme == lexer.lexicon.kAsync) {
          advance();
          stmt = _parseFunction(isAsync: true);
        } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          stmt = _parseFunction();
        } else if (curTok.lexeme == lexer.lexicon.kStruct) {
          stmt = _parseStructDecl();
        } else {
          final err = HTError.unexpected(HTLocale.current.namespace,
              HTLocale.current.declarationStatement, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
          final errToken = advance();
          stmt = ASTEmptyLine(
              source: currentSource,
              line: errToken.line,
              column: errToken.column,
              offset: errToken.offset);
        }
      case ParseStyle.classDefinition:
        // final isOverrided = expect([lexer.lexicon.kOverride], consume: true);
        // if (isOverrided) {
        //   final err = HTError.unsupported(
        //       lexer.lexicon.kOverride, kHetuVersion.toString(),
        //       filename: currrentFileName,
        //       line: curTok.line,
        //       column: curTok.column,
        //       offset: curTok.offset,
        //       length: curTok.length);
        //   errors.add(err);
        // }
        final isExternal = expect([lexer.lexicon.kExternal], consume: true) ||
            (_currentClassDeclaration?.isExternal ?? false);
        final isStatic = expect([lexer.lexicon.kStatic], consume: true);
        if (curTok.lexeme == lexer.lexicon.kTypeDef) {
          if (isExternal) {
            final err = HTError.external(HTLocale.current.typeAliasDeclaration,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseTypeAliasDecl();
          }
        } else {
          if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
            stmt = _parseVarDecl(
              classId: _currentClassDeclaration?.id,
              // isOverrided: isOverrided,
              isExternal: isExternal,
              isMutable: true,
              isStatic: isStatic,
              lateInitialize: true,
            );
          } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
            stmt = _parseVarDecl(
              classId: _currentClassDeclaration?.id,
              // isOverrided: isOverrided,
              isExternal: isExternal,
              isStatic: isStatic,
              lateInitialize: true,
            );
          } else if (curTok.lexeme == lexer.lexicon.kLate) {
            stmt = _parseVarDecl(
              classId: _currentClassDeclaration?.id,
              // isOverrided: isOverrided,
              isExternal: isExternal,
              isStatic: isStatic,
              lateFinalize: true,
            );
          } else if (curTok.lexeme == lexer.lexicon.kConst) {
            if (isStatic) {
              stmt = _parseVarDecl(
                // isConst: true,
                classId: _currentClassDeclaration?.id,
              );
            } else {
              final err = HTError.external(
                HTLocale.current.typeAliasDeclaration,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length,
              );
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset,
              );
            }
          } else if (curTok.lexeme == lexer.lexicon.kAsync) {
            if (isExternal) {
              final err = HTError.external(
                HTLocale.current.asyncFunction,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length,
              );
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset,
              );
            } else {
              stmt = _parseFunction(
                // category: FunctionCategory.method,
                classId: _currentClassDeclaration?.id,
                isAsync: true,
                // isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic,
              );
            }
          } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
            stmt = _parseFunction(
                // category: FunctionCategory.method,
                classId: _currentClassDeclaration?.id,
                // isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.lexeme == lexer.lexicon.kGet) {
            stmt = _parseFunction(
                category: FunctionCategory.getter,
                classId: _currentClassDeclaration?.id,
                // isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.lexeme == lexer.lexicon.kSet) {
            stmt = _parseFunction(
                category: FunctionCategory.setter,
                classId: _currentClassDeclaration?.id,
                // isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (lexer.lexicon.kConstructors.contains(curTok.lexeme)) {
            if (isStatic) {
              final err = HTError.unexpected(lexer.lexicon.kStatic,
                  HTLocale.current.declarationStatement, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal && !_currentClassDeclaration!.isExternal) {
              final err = HTError.external(HTLocale.current.constructor,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                category: FunctionCategory.constructor,
                classId: _currentClassDeclaration?.id,
                isExternal: isExternal,
              );
            }
          } else if (curTok.lexeme == lexer.lexicon.kFactory) {
            if (isStatic) {
              final err = HTError.unexpected(lexer.lexicon.kStatic,
                  HTLocale.current.declarationStatement, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal && !_currentClassDeclaration!.isExternal) {
              final err = HTError.external(HTLocale.current.factory,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                category: FunctionCategory.factoryConstructor,
                classId: _currentClassDeclaration?.id,
                isExternal: isExternal,
                isStatic: true,
              );
            }
          } else {
            final err = HTError.unexpected(HTLocale.current.classDefinition,
                HTLocale.current.declarationStatement, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        }
      case ParseStyle.structDefinition:
        final isExternal = expect([lexer.lexicon.kExternal], consume: true);
        final isStatic = expect([lexer.lexicon.kStatic], consume: true);
        if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
          stmt = _parseVarDecl(
            classId: _currentStructId,
            isExternal: isExternal,
            isMutable: true,
            isStatic: isStatic,
            isField: true,
            lateInitialize: true,
          );
        } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
          stmt = _parseVarDecl(
            classId: _currentStructId,
            isExternal: isExternal,
            isStatic: isStatic,
            isField: true,
            lateInitialize: true,
          );
        } else if (curTok.lexeme == lexer.lexicon.kAsync) {
          advance();
          stmt = _parseFunction(
            // category: FunctionCategory.method,
            classId: _currentStructId,
            isAsync: true,
            isExternal: isExternal,
            isStatic: isStatic,
            isField: true,
          );
        } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          stmt = _parseFunction(
            // category: FunctionCategory.method,
            classId: _currentStructId,
            isExternal: isExternal,
            isStatic: isStatic,
            isField: true,
          );
        }
        // else if (curTok.lexeme == lexer.lexicon.kAsync) {
        //   if (isExternal) {
        //     final err = HTError.external(HTLocale.current.asyncFunction,
        //         filename: currrentFileName,
        //         line: curTok.line,
        //         column: curTok.column,
        //         offset: curTok.offset,
        //         length: curTok.length);
        //     errors.add(err);
        //     final errToken = advance();
        //     stmt = ASTEmptyLine(
        //         source: currentSource,
        //         line: errToken.line,
        //         column: errToken.column,
        //         offset: errToken.offset);
        //   } else {
        //     stmt = _parseFunction(
        //  //       category: FunctionCategory.method,
        //         classId: _currentStructId,
        //         isAsync: true,
        //         isField: true,
        //         isExternal: isExternal,
        //         isStatic: isStatic);
        //   }
        // }
        else if (curTok.lexeme == lexer.lexicon.kGet) {
          stmt = _parseFunction(
            category: FunctionCategory.getter,
            classId: _currentStructId,
            isExternal: isExternal,
            isStatic: isStatic,
            isField: true,
          );
        } else if (curTok.lexeme == lexer.lexicon.kSet) {
          stmt = _parseFunction(
            category: FunctionCategory.setter,
            classId: _currentStructId,
            isExternal: isExternal,
            isStatic: isStatic,
            isField: true,
          );
        } else if (lexer.lexicon.kConstructors.contains(curTok.lexeme)) {
          if (isStatic) {
            final err = HTError.unexpected(lexer.lexicon.kStatic,
                HTLocale.current.declarationStatement, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else if (isExternal) {
            final err = HTError.external(HTLocale.current.constructor,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseFunction(
              category: FunctionCategory.constructor,
              classId: _currentStructId,
              isExternal: isExternal,
              isField: true,
            );
          }
        } else {
          final err = HTError.unexpected(HTLocale.current.structDefinition,
              HTLocale.current.declarationStatement, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
          final errToken = advance();
          stmt = ASTEmptyLine(
            source: currentSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset,
          );
        }
      case ParseStyle.functionDefinition:
        if (curTok.lexeme == lexer.lexicon.kTypeDef) {
          stmt = _parseTypeAliasDecl();
        } else if (curTok.lexeme == lexer.lexicon.kNamespace) {
          stmt = _parseNamespaceDecl();
        } else if (curTok.lexeme == lexer.lexicon.kAssert) {
          stmt = _parseAssertStmt();
        } else if (curTok.lexeme == lexer.lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(isAbstract: true, lateResolve: false);
        } else if (curTok.lexeme == lexer.lexicon.kClass) {
          stmt = _parseClassDecl(lateResolve: false);
        } else if (curTok.lexeme == lexer.lexicon.kEnum) {
          stmt = _parseEnumDecl();
        } else if (lexer.lexicon.kMutables.contains(curTok.lexeme)) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl(isMutable: true);
          } else {
            stmt = _parseVarDecl(isMutable: true);
          }
        } else if (curTok.lexeme == lexer.lexicon.kImmutable) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl();
          } else {
            stmt = _parseVarDecl();
          }
        } else if (curTok.lexeme == lexer.lexicon.kConst) {
          if (lexer.lexicon.destructuringDeclarationMarks
              .contains(peek(1).lexeme)) {
            stmt = _parseDestructuringDecl();
          } else {
            stmt = _parseVarDecl(
                // isConst: true,
                );
          }
        } else if (curTok.lexeme == lexer.lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true);
        } else if (curTok.lexeme == lexer.lexicon.kAsync) {
          advance();
          stmt = _parseFunction(isAsync: true);
        } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          stmt = _parseFunction();
        } else if (curTok.lexeme == lexer.lexicon.kStruct) {
          stmt = _parseStructDecl(); // (lateInitialize: false);
        } else if (curTok.lexeme == lexer.lexicon.kDelete) {
          stmt = _parseDeleteStmt();
        } else if (curTok.lexeme == lexer.lexicon.kIf) {
          stmt = _parseIf();
        } else if (curTok.lexeme == lexer.lexicon.kWhile) {
          stmt = _parseWhileStmt();
        } else if (curTok.lexeme == lexer.lexicon.kDo) {
          stmt = _parseDoStmt();
        } else if (curTok.lexeme == lexer.lexicon.kFor) {
          stmt = _parseForStmt();
        } else if (lexer.lexicon.kSwitchs.contains(curTok.lexeme)) {
          stmt = _parseSwitch();
        } else if (curTok.lexeme == lexer.lexicon.kThrow) {
          stmt = _parseThrowStmt();
        } else if (curTok.lexeme == lexer.lexicon.kBreak) {
          if (!_isInLoop) {
            final err = HTError.misplacedBreak(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
          }
          final keyword = advance();
          final hasEndOfStmtMark = parseEndOfStmtMark();
          stmt = BreakStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.lexeme == lexer.lexicon.kContinue) {
          if (!_isInLoop) {
            final err = HTError.misplacedContinue(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
          }
          final keyword = advance();
          final hasEndOfStmtMark = parseEndOfStmtMark();
          stmt = ContinueStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.lexeme == lexer.lexicon.kReturn) {
          if (_currentFunctionDeclaration?.category ==
              FunctionCategory.constructor) {
            final err = HTError.misplacedReturn(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
          }
          stmt = _parseReturnStmt();
        } else {
          stmt = _parseExprStmt();
        }
      case ParseStyle.expression:
        stmt = parseExpr();
    }

    currentPrecedings = savedPrecedings;
    setPrecedings(stmt);
    // it's possible that there's trailing comment after end of stmt mark (;).
    handleTrailing(stmt);

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(lexer.lexicon.kAssert);
    match(lexer.lexicon.groupExprStart);
    final expr = parseExpr();
    match(lexer.lexicon.groupExprEnd);
    final hasEndOfStmtMark = parseEndOfStmtMark();
    final stmt = AssertStmt(expr,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  ThrowStmt _parseThrowStmt() {
    final keyword = match(lexer.lexicon.kThrow);
    final message = parseExpr();
    final hasEndOfStmtMark = parseEndOfStmtMark();
    final stmt = ThrowStmt(message,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: message.end - keyword.offset);
    return stmt;
  }

  ASTEmptyLine? _handleCallArguments(
      List<ASTNode> positionalArgs, Map<String, ASTNode> namedArgs) {
    bool hasAnyArgs = false;
    final savedPrecedings = savePrecedings();
    // call arguments are a bit complex so we didn't use [parseExprList] here.
    while (curTok.lexeme != lexer.lexicon.functionParameterEnd &&
        curTok.lexeme != Token.endOfFile) {
      // it's possible that it's an empty arguments list, so we manually handle precedings here
      handlePrecedings();
      if (curTok.lexeme == lexer.lexicon.functionParameterEnd) break;
      hasAnyArgs = true;
      if (curTok is TokenIdentifier &&
          peek(1).lexeme == lexer.lexicon.namedArgumentValueIndicator) {
        final name = matchId().lexeme;
        match(lexer.lexicon.namedArgumentValueIndicator);
        final namedArg = parseExpr();
        handleTrailing(namedArg,
            endMarkForCommaExpressions: lexer.lexicon.functionParameterEnd);
        namedArgs[name] = namedArg;
      } else {
        ASTNode positionalArg;
        if (curTok.lexeme == lexer.lexicon.spreadSyntax) {
          final spreadTok = advance();
          final spread = parseExpr();
          positionalArg = SpreadExpr(spread,
              source: currentSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: spread.length);
        } else {
          positionalArg = parseExpr();
        }
        handleTrailing(positionalArg,
            endMarkForCommaExpressions: lexer.lexicon.functionParameterEnd);
        positionalArgs.add(positionalArg);
      }
    }
    final endTok = match(lexer.lexicon.functionParameterEnd);
    if (hasAnyArgs) {
      return null;
    }
    final empty = ASTEmptyLine(
      source: currentSource,
      line: endTok.line,
      column: endTok.column,
      offset: endTok.offset,
      length: endTok.length,
    );
    setPrecedings(empty);
    // empty line's documentation are within the brackets
    // so we restore the precedings to previous state
    currentPrecedings = savedPrecedings;
    return empty;
  }

  /// Recursive descent parsing
  ///
  /// Assignment operator =
  /// precedence 1, associativity right
  @override
  ASTNode parseExpr() {
    ASTNode? expr;
    final left = _parseTernaryExpr();
    if (lexer.lexicon.assignments.contains(curTok.lexeme)) {
      if (!_isLegalLeftValue) {
        final err = HTError.invalidLeftValue(
            filename: currrentFileName,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: left.length);
        errors.add(err);
      }
      final op = advance();
      final right = parseExpr();
      expr = AssignExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else {
      expr = left;
    }
    handleTrailing(left);
    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3
  /// precedence 3, associativity right
  ASTNode _parseTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([lexer.lexicon.ternaryThen], consume: true)) {
      _isLegalLeftValue = false;
      final thenBranch = _parseTernaryExpr();
      match(lexer.lexicon.ternaryElse);
      final elseBranch = _parseTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: currentSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// If null: e1 ?? e2
  /// precedence 4, associativity left
  ASTNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.lexeme == lexer.lexicon.ifNull) {
      _isLegalLeftValue = false;
      while (curTok.lexeme == lexer.lexicon.ifNull) {
        final op = advance();
        final right = _parseLogicalOrExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical or: ||
  /// precedence 5, associativity left
  ASTNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.lexeme == lexer.lexicon.logicalOr) {
      _isLegalLeftValue = false;
      while (curTok.lexeme == lexer.lexicon.logicalOr) {
        final op = advance();
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical and: &&
  /// precedence 6, associativity left
  ASTNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.lexeme == lexer.lexicon.logicalAnd) {
      _isLegalLeftValue = false;
      while (curTok.lexeme == lexer.lexicon.logicalAnd) {
        final op = advance();
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical equal: ==, !=
  /// precedence 7, associativity none
  ASTNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (lexer.lexicon.equalitys.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      final op = advance();
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Logical compare: <, >, <=, >=, as, is, is!, in, in!
  /// precedence 8, associativity none
  ASTNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (lexer.lexicon.logicalRelationals.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      final op = advance();
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexer.lexicon.setRelationals.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexer.lexicon.kIn) {
        opLexeme = expect([lexer.lexicon.logicalNot], consume: true)
            ? lexer.lexicon.kNotIn
            : lexer.lexicon.kIn;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, opLexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexer.lexicon.typeRelationals.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexer.lexicon.kIs) {
        opLexeme = expect([lexer.lexicon.logicalNot], consume: true)
            ? lexer.lexicon.kIsNot
            : lexer.lexicon.kIs;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Add: +, -
  /// precedence 13, associativity left
  ASTNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (lexer.lexicon.additives.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      while (lexer.lexicon.additives.contains(curTok.lexeme)) {
        final op = advance();
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Multiply *, /, ~/, %
  /// precedence 14, associativity left
  ASTNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (lexer.lexicon.multiplicatives.contains(curTok.lexeme)) {
      _isLegalLeftValue = false;
      while (lexer.lexicon.multiplicatives.contains(curTok.lexeme)) {
        final op = advance();
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Prefix -e, !e，++e, --e, await e
  /// precedence 15, associativity none
  ASTNode _parseUnaryPrefixExpr() {
    if (!lexer.lexicon.unaryPrefixes.contains(curTok.lexeme)) {
      return _parseUnaryPostfixExpr();
    } else {
      _isLegalLeftValue = false;
      final op = advance();
      final value = _parseUnaryPostfixExpr();
      if (op.lexeme == lexer.lexicon.kDeclTypeof) {
        if (value is! IdentifierExpr) {
          final err = HTError.invalidDeclTypeOfValue(
              filename: currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors.add(err);
        }
      }
      if (lexer.lexicon.unaryPrefixesThatChangeTheValue.contains(op.lexeme)) {
        if (!_isLegalLeftValue) {
          final err = HTError.invalidLeftValue(
              filename: currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors.add(err);
        }
      }
      final isAwait = op.lexeme == lexer.lexicon.kAwait;
      if (isAwait) {
        if (_currentFunctionDeclaration != null &&
            !_currentFunctionDeclaration!.isAsync) {
          final err = HTError.awaitWithoutAsync(
              filename: currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors.add(err);
        }
      }

      return UnaryPrefixExpr(op.lexeme, value,
          isAwait: isAwait,
          source: currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// Postfix e., e?., e[], e?[], e(), e?(), e++, e--
  /// precedence 16, associativity right
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (lexer.lexicon.unaryPostfixs.contains(curTok.lexeme)) {
      final op = advance();
      if (op.lexeme == lexer.lexicon.memberGet) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        _isLegalLeftValue = true;
        final name = matchId();
        final key = IdentifierExpr(
            name.literal, // use literal here to strip the graves.
            isLocal: false,
            source: currentSource,
            line: name.line,
            column: name.column,
            offset: name.offset,
            length: name.length);
        expr = MemberExpr(expr, key,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.nullableMemberGet) {
        _isLegalLeftValue = false;
        final name = matchId();
        final key = IdentifierExpr(
            name.literal, // use literal here to strip the graves.
            isLocal: false,
            source: currentSource,
            line: name.line,
            column: name.column,
            offset: name.offset,
            length: name.length);
        expr = MemberExpr(expr, key,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.subGetStart) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        var indexExpr = parseExpr();
        _isLegalLeftValue = true;
        match(lexer.lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.nullableSubGet) {
        var indexExpr = parseExpr();
        _isLegalLeftValue = true;
        match(lexer.lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.nullableFunctionArgumentCall) {
        _isLegalLeftValue = false;
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        _handleCallArguments(positionalArgs, namedArgs);
        expr = CallExpr(expr,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.functionParameterStart) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        _isLegalLeftValue = false;
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        _handleCallArguments(positionalArgs, namedArgs);
        expr = CallExpr(expr,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.lexeme == lexer.lexicon.postIncrement ||
          op.lexeme == lexer.lexicon.postDecrement) {
        if (!_isLegalLeftValue) {
          final err = HTError.invalidLeftValue(
              filename: currrentFileName,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: expr.length);
          errors.add(err);
        }
        expr = UnaryPostfixExpr(expr, op.lexeme,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      }
    }
    return expr;
  }

  /// Expression without associativity
  ASTNode _parsePrimaryExpr() {
    handlePrecedings();

    ASTNode? expr;

    // literal function expression parsing
    // We cannot use 'switch case' here because we have to use lexicon's value,
    // which is not constant.
    // We also cannot put this paragraph in else if, because
    // the literal function parsing need to look ahead a lot of tokens,
    // thus we have to try parse as literal function even if it may not be.
    if (curTok.lexeme == lexer.lexicon.functionParameterStart) {
      final tokenAtParameterStart = curTok.next;
      final tokenAfterParameterList = seekGroupClosing({
        lexer.lexicon.functionParameterStart: lexer.lexicon.functionParameterEnd
      });
      if ((tokenAtParameterStart?.lexeme == lexer.lexicon.groupExprEnd ||
              (tokenAtParameterStart is TokenIdentifier &&
                  (tokenAtParameterStart.next?.lexeme == lexer.lexicon.comma ||
                      tokenAtParameterStart.next?.lexeme ==
                          lexer.lexicon.typeIndicator ||
                      tokenAtParameterStart.next?.lexeme ==
                          lexer.lexicon.groupExprEnd))) &&
          //     (tokenAfterGroupExprEnd.type ==
          //         lexer.lexicon.literalFunctionDefinitionIndicator)) {
          (tokenAfterParameterList.lexeme == lexer.lexicon.blockStart ||
              tokenAfterParameterList.lexeme ==
                  lexer.lexicon.singleLineFunctionIndicator ||
              tokenAfterParameterList.lexeme == lexer.lexicon.kAsync)) {
        _isLegalLeftValue = false;
        expr = _parseFunction(category: FunctionCategory.literal);
      }
    }

    if (expr == null) {
      if (curTok.lexeme == lexer.lexicon.kNull) {
        final token = advance();
        _isLegalLeftValue = false;
        expr = ASTLiteralNull(
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok is TokenBooleanLiteral) {
        final token = advance() as TokenBooleanLiteral;
        _isLegalLeftValue = false;
        expr = ASTLiteralBoolean(token.literal,
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok is TokenIntegerLiteral) {
        final token = advance() as TokenIntegerLiteral;
        _isLegalLeftValue = false;
        expr = ASTLiteralInteger(token.literal,
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok is TokenFloatLiteral) {
        final token = advance() as TokenFloatLiteral;
        _isLegalLeftValue = false;
        expr = ASTLiteralFloat(token.literal,
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok is TokenStringInterpolation) {
        final token = advance() as TokenStringInterpolation;
        final interpolations = <ASTNode>[];
        final savedCurrent = curTok;
        final savedFirst = firstTok;
        final savedEnd = endOfFile;
        final savedLine = line;
        final savedColumn = column;
        final parser = HTParserHetu();
        for (final token in token.interpolations) {
          final nodes = parser.parseTokens(token,
              source: currentSource, style: ParseStyle.expression);
          ASTNode? expr;
          for (final node in nodes) {
            if (node is ASTEmptyLine) continue;
            if (expr == null) {
              expr = node;
            } else {
              final err = HTError.stringInterpolation(
                  filename: currrentFileName,
                  line: node.line,
                  column: node.column,
                  offset: node.offset,
                  length: node.length);
              errors.add(err);
              break;
            }
          }
          if (expr != null) {
            interpolations.add(expr);
          } else {
            // parser will always contain at least a empty line expr
            interpolations.add(nodes.first);
          }
        }
        curTok = savedCurrent;
        firstTok = savedFirst;
        endOfFile = savedEnd;
        line = savedLine;
        column = savedColumn;
        var i = 0;
        final text = token.literal.replaceAllMapped(
            RegExp(lexer.lexicon.stringInterpolationPattern),
            (Match m) =>
                '${lexer.lexicon.stringInterpolationStart}${i++}${lexer.lexicon.stringInterpolationEnd}');
        _isLegalLeftValue = false;
        expr = ASTStringInterpolation(
            text, token.startMark, token.endMark, interpolations,
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok is TokenStringLiteral) {
        final token = matchString();
        _isLegalLeftValue = false;
        expr = ASTLiteralString(token.literal, token.startMark, token.endMark,
            source: currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      } else if (curTok.lexeme == lexer.lexicon.kThis) {
        // this expression
        if (_currentFunctionDeclaration?.category != FunctionCategory.literal &&
            (_currentClassDeclaration == null && _currentStructId == null)) {
          final err = HTError.misplacedThis(
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
        }
        final keyword = advance();
        _isLegalLeftValue = false;
        expr = IdentifierExpr(keyword.lexeme,
            source: currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      } else if (curTok.lexeme == lexer.lexicon.kSuper) {
        // super constructor call
        if (_currentClassDeclaration == null ||
            _currentFunctionDeclaration == null) {
          final err = HTError.misplacedSuper(
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
        }
        final keyword = advance();
        _isLegalLeftValue = false;
        expr = IdentifierExpr(keyword.lexeme,
            source: currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      } else if (curTok.lexeme == lexer.lexicon.kNew) {
        // constructor call
        final keyword = advance();
        _isLegalLeftValue = false;
        final idTok = matchId();
        final id = IdentifierExpr.fromToken(idTok,
            isMarked: idTok.isMarked, source: currentSource);
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        ASTEmptyLine? empty;
        if (expect([lexer.lexicon.functionParameterStart], consume: true)) {
          empty = _handleCallArguments(positionalArgs, namedArgs);
        }
        expr = CallExpr(id,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            documentationsWithinEmptyContent: empty,
            hasNewOperator: true,
            source: currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else if (curTok.lexeme == lexer.lexicon.kIf) {
        // if expression
        _isLegalLeftValue = false;
        expr = _parseIf(isStatement: false);
      } else if (lexer.lexicon.kSwitchs.contains(curTok.lexeme)) {
        // switch expression
        _isLegalLeftValue = false;
        expr = _parseSwitch(isStatement: false);
      } else if (curTok.lexeme == lexer.lexicon.groupExprStart) {
        // group expression
        final start = advance();
        final innerExpr = parseExpr();
        final end = match(lexer.lexicon.groupExprEnd);
        _isLegalLeftValue = false;
        expr = GroupExpr(innerExpr,
            source: currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.offset + end.length - start.offset);
      } else if (curTok.lexeme == lexer.lexicon.listStart) {
        // literal list value
        final start = advance();
        final listExprs = parseExprList(
          endToken: lexer.lexicon.listEnd,
          parseFunction: () {
            if (curTok.lexeme == lexer.lexicon.listEnd) return null;
            ASTNode item;
            if (curTok.lexeme == lexer.lexicon.spreadSyntax) {
              final spreadTok = advance();
              item = parseExpr();
              final spreadExpr = SpreadExpr(item,
                  source: currentSource,
                  line: spreadTok.line,
                  column: spreadTok.column,
                  offset: spreadTok.offset,
                  length: item.end - spreadTok.offset);
              setPrecedings(spreadExpr);
              return spreadExpr;
            } else {
              return parseExpr();
            }
          },
        );
        final endTok = match(lexer.lexicon.listEnd);
        _isLegalLeftValue = false;
        expr = ListExpr(listExprs,
            source: currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: endTok.end - start.offset);
      } else if (curTok.lexeme == lexer.lexicon.structStart) {
        _isLegalLeftValue = false;
        expr = _parseStructObj();
      } else if (curTok.lexeme == lexer.lexicon.kStruct) {
        _isLegalLeftValue = false;
        expr = _parseStructObj(hasKeyword: true);
      } else if (curTok.lexeme == lexer.lexicon.kAsync) {
        _isLegalLeftValue = false;
        expr =
            _parseFunction(category: FunctionCategory.literal, isAsync: true);
      } else if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
        _isLegalLeftValue = false;
        expr = _parseFunction(category: FunctionCategory.literal);
      } else if (curTok.lexeme == lexer.lexicon.kTypeValue) {
        // `type` is a common word that could appear in a json5 file,
        // so we used a special keyword `typeval` here to parse a literal type value
        _isLegalLeftValue = false;
        expr = _parseTypeExpr(handleDeclKeyword: true, isLocal: true);
      } else if (curTok is TokenIdentifier) {
        final id = advance() as TokenIdentifier;
        final isLocal = curTok.lexeme != lexer.lexicon.assign;
        // TODO: type arguments
        _isLegalLeftValue = true;
        expr = IdentifierExpr.fromToken(id,
            isMarked: id.isMarked, isLocal: isLocal, source: currentSource);
      }
    }

    if (expr == null) {
      final err = HTError.unexpected(HTLocale.current.primaryExpression,
          HTLocale.current.expression, curTok.lexeme,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
      final errToken = advance();
      expr = ASTEmptyLine(
          source: currentSource,
          line: errToken.line,
          column: errToken.column,
          offset: errToken.offset);
    }

    setPrecedings(expr);
    handleTrailing(expr);
    return expr;
  }

  CommaExpr _handleCommaExpr(String endMark, {bool isLocal = true}) {
    final List<ASTNode> list = parseExprList(
      endToken: endMark,
      parseFunction: () => parseExpr(),
    );
    assert(list.isNotEmpty);
    return CommaExpr(list,
        isLocal: isLocal,
        source: currentSource,
        line: list.first.line,
        column: list.first.column,
        offset: list.first.offset,
        length: curTok.offset - list.first.offset);
  }

  InOfExpr _handleInOfExpr() {
    final opTok = advance();
    final collection = parseExpr();
    return InOfExpr(
        collection, opTok.lexeme == lexer.lexicon.kOf ? true : false,
        line: collection.line,
        column: collection.column,
        offset: collection.offset,
        length: curTok.offset - collection.offset);
  }

  TypeExpr _parseTypeExpr({
    bool handleDeclKeyword = false,
    bool isLocal = false,
    bool isReturnType = false,
  }) {
    if (handleDeclKeyword) {
      match(lexer.lexicon.kTypeValue);
    }
    // function type
    if (curTok.lexeme == lexer.lexicon.groupExprStart) {
      final savedPrecedings = savePrecedings();
      final startTok = advance();
      // TODO: generic parameters
      var isOptional = false;
      var isNamed = false;
      final parameters = <ParamTypeExpr>[];
      // function parameters are a bit complex so we didn't use [parseExprList] here.
      while (curTok.lexeme != lexer.lexicon.functionParameterEnd &&
          curTok.lexeme != Token.endOfFile) {
        handlePrecedings();
        if (curTok.lexeme == lexer.lexicon.functionParameterEnd) {
          // TODO: store comments within empty function parameter list
          break;
        }
        // optional positional args
        if (!isOptional &&
            !isNamed &&
            expect([lexer.lexicon.functionPositionalParameterStart],
                consume: true)) {
          isOptional = true;
          bool alreadyHasVariadic = false;
          final optionalPositionalParameters = parseExprList(
            endToken: lexer.lexicon.functionPositionalParameterEnd,
            parseFunction: () {
              final isVariadic =
                  expect([lexer.lexicon.variadicArgs], consume: true);
              if (alreadyHasVariadic && isVariadic) {
                final err = HTError.unexpected(
                    HTLocale.current.functionTypeExpression,
                    HTLocale.current.paramTypeExpression,
                    lexer.lexicon.variadicArgs,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
              }
              alreadyHasVariadic = isVariadic;
              final paramType = _parseTypeExpr();
              final param = ParamTypeExpr(paramType,
                  isOptionalPositional: isOptional,
                  isVariadic: isVariadic,
                  source: currentSource,
                  line: paramType.line,
                  column: paramType.column,
                  offset: paramType.offset,
                  length: curTok.offset - paramType.offset);
              setPrecedings(param);
              return param;
            },
          );
          match(lexer.lexicon.functionPositionalParameterEnd);
          parameters.addAll(optionalPositionalParameters);
        }
        // optional named args
        else if (!isOptional &&
            !isNamed &&
            expect([lexer.lexicon.functionNamedParameterStart],
                consume: true)) {
          isNamed = true;
          final namedParameters = parseExprList(
            endToken: lexer.lexicon.functionNamedParameterEnd,
            parseFunction: () {
              final paramId = matchId();
              final paramSymbol =
                  IdentifierExpr.fromToken(paramId, source: currentSource);
              match(lexer.lexicon.typeIndicator);
              final paramType = _parseTypeExpr();
              final param = ParamTypeExpr(paramType,
                  id: paramSymbol,
                  source: currentSource,
                  line: paramType.line,
                  column: paramType.column,
                  offset: paramType.offset,
                  length: curTok.offset - paramType.offset);
              setPrecedings(param);
              return param;
            },
          );
          match(lexer.lexicon.functionNamedParameterEnd);
          parameters.addAll(namedParameters);
        }
        // mandatory positional args
        else {
          bool isVariadic = expect([lexer.lexicon.variadicArgs], consume: true);
          final paramType = _parseTypeExpr();
          final param = ParamTypeExpr(paramType,
              isOptionalPositional: isOptional,
              isVariadic: isVariadic,
              source: currentSource,
              line: paramType.line,
              column: paramType.column,
              offset: paramType.offset,
              length: curTok.offset - paramType.offset);
          parameters.add(param);
          if (isVariadic) break;
          handleTrailing(param,
              endMarkForCommaExpressions: lexer.lexicon.functionParameterEnd);
        }
      }
      match(lexer.lexicon.functionParameterEnd);
      match(lexer.lexicon.returnTypeIndicator);
      final returnType = _parseTypeExpr(isReturnType: true);
      final funcType = FuncTypeExpr(returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: currentSource,
          line: startTok.line,
          column: startTok.column,
          offset: startTok.offset,
          length: curTok.offset - startTok.offset);
      currentPrecedings = savedPrecedings;
      setPrecedings(funcType);
      return funcType;
    }
    // structural type (interface of struct)
    else if (curTok.lexeme == lexer.lexicon.structStart) {
      final savedPrecedings = savePrecedings();
      final startTok = advance();
      final fieldTypes = parseExprList(
        endToken: lexer.lexicon.blockEnd,
        parseFunction: () {
          if (curTok is TokenStringLiteral || curTok is TokenIdentifier) {
            final savedPrecedings = savePrecedings();
            final idTok = advance();
            match(lexer.lexicon.typeIndicator);
            final typeExpr = _parseTypeExpr();
            final expr = FieldTypeExpr(idTok.literal, typeExpr);
            currentPrecedings = savedPrecedings;
            setPrecedings(expr);
            return expr;
          } else {
            final err = HTError.structMemberId(curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            advance();
            return null;
          }
        },
      );
      match(lexer.lexicon.blockEnd);
      final structuralType = StructuralTypeExpr(
        fieldTypes: fieldTypes,
        isLocal: isLocal,
        source: currentSource,
        line: startTok.line,
        column: startTok.column,
        length: curTok.offset - startTok.offset,
      );
      currentPrecedings = savedPrecedings;
      setPrecedings(structuralType);
      return structuralType;
    }
    // intrinsic types & nominal types (class)
    else {
      handlePrecedings();
      // id could be identifier or keyword.
      final idTok = advance();
      var id = IdentifierExpr.fromToken(idTok, source: currentSource);
      if (idTok.lexeme == lexer.lexicon.kAny) {
        final typeExpr = IntrinsicTypeExpr(
          id: id,
          isTop: true,
          isBottom: true,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(typeExpr);
        return typeExpr;
      } else if (idTok.lexeme == lexer.lexicon.kUnknown) {
        final typeExpr = IntrinsicTypeExpr(
          id: id,
          isTop: true,
          isBottom: false,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(typeExpr);
        return typeExpr;
      } else if (idTok.lexeme == lexer.lexicon.kVoid) {
        if (!isReturnType) {
          final err = HTError.unexpected(
              HTLocale.current.typeExpression, HTLocale.current.typeName, id.id,
              filename: currrentFileName,
              line: id.line,
              column: id.column,
              offset: id.offset,
              length: id.length);
          errors.add(err);
        }
        final typeExpr = IntrinsicTypeExpr(
          id: id,
          isTop: false,
          isBottom: true,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(typeExpr);
        return typeExpr;
      } else if (idTok.lexeme == lexer.lexicon.kNever) {
        if (!isReturnType) {
          final err = HTError.unexpected(
              HTLocale.current.typeExpression, HTLocale.current.typeName, id.id,
              filename: currrentFileName,
              line: id.line,
              column: id.column,
              offset: id.offset,
              length: id.length);
          errors.add(err);
        }
        final typeExpr = IntrinsicTypeExpr(
          id: id,
          isTop: false,
          isBottom: true,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(typeExpr);
        return typeExpr;
      }
      // `type`, `function`, `namespace` types:
      else if (lexer.lexicon.builtinIntrinsicTypes.contains(idTok.lexeme)) {
        final typeExpr = IntrinsicTypeExpr(
          id: id,
          isTop: false,
          isBottom: false,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(typeExpr);
        return typeExpr;
      } else {
        if (idTok is! TokenIdentifier) {
          final err = HTError.unexpected(HTLocale.current.typeExpression,
              HTLocale.current.identifier, idTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors.add(err);
        }
        List<IdentifierExpr> namespacesWithin = [];
        if (curTok.lexeme == lexer.lexicon.memberGet) {
          while (expect([lexer.lexicon.memberGet], consume: true)) {
            namespacesWithin.add(id);
            final nextIdTok = matchId();
            id = IdentifierExpr.fromToken(nextIdTok, source: currentSource);
          }
        }
        List<TypeExpr> typeArgs = [];
        if (expect([lexer.lexicon.typeListStart], consume: true)) {
          typeArgs = parseExprList(
            endToken: lexer.lexicon.typeListEnd,
            parseFunction: () => _parseTypeExpr(),
          );
          match(lexer.lexicon.typeListEnd);
          if (typeArgs.isEmpty) {
            final err = HTError.unexpectedEmptyList(
                HTLocale.current.typeArguments,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.end - idTok.offset);
            errors.add(err);
          }
        }
        final isNullable =
            expect([lexer.lexicon.nullableTypePostfix], consume: true);
        final nominalType = NominalTypeExpr(
          id: id,
          namespacesWithin: namespacesWithin,
          arguments: typeArgs,
          isNullable: isNullable,
          isLocal: isLocal,
          source: currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset,
        );
        setPrecedings(nominalType);
        return nominalType;
      }
    }
  }

  BlockStmt _parseBlockStmt({
    String? id,
    ParseStyle sourceType = ParseStyle.functionDefinition,
    bool isScriptBlock = true,
    bool isLoop = false,
    String? blockStartMark,
  }) {
    final startMark = blockStartMark ?? lexer.lexicon.blockStart;
    assert(lexer.lexicon.groupClosings.keys.contains(startMark));
    final startTok = match(startMark);
    final String endMark = lexer.lexicon.groupClosings[startMark]!;
    final savedPrecedings = savePrecedings();
    final savedIsLoopFlag = _isInLoop;
    if (isLoop) _isInLoop = true;
    final statements = parseExprList(
      endToken: endMark,
      parseFunction: () {
        final stmt = parseStmt(style: sourceType);
        if (stmt != null) {
          if (sourceType != ParseStyle.functionDefinition && stmt.isAwait) {
            final err = HTError.awaitExpression(
                filename: currrentFileName,
                line: stmt.line,
                column: stmt.column,
                offset: stmt.offset,
                length: stmt.length);
            errors.add(err);
          }
        }
        return stmt;
      },
      handleComma: false,
    );
    if (statements.isEmpty) {
      final empty = ASTEmptyLine(
          source: currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.offset - (curTok.previous?.end ?? startTok.end));
      setPrecedings(empty);
      statements.add(empty);
    }
    _isInLoop = savedIsLoopFlag;
    final endTok = match(endMark);
    final block = BlockStmt(statements,
        id: id,
        isCodeBlock: isScriptBlock,
        source: currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: endTok.offset - startTok.offset);
    currentPrecedings = savedPrecedings;
    setPrecedings(block);
    return block;
  }

  ASTNode _parseExprStmt() {
    final expr = parseExpr();
    final hasEndOfStmtMark = parseEndOfStmtMark();
    final stmt = ExprStmt(expr,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: expr.line,
        column: expr.column,
        offset: expr.offset,
        length: curTok.offset - expr.offset);
    handleTrailing(stmt);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance();
    ASTNode? expr;
    bool hasEndOfStmtMark = true;
    if (curTok.lexeme != lexer.lexicon.blockEnd &&
        curTok.lexeme != lexer.lexicon.endOfStatementMark) {
      expr = parseExpr();
      if (!expr.isBlock) {
        hasEndOfStmtMark = parseEndOfStmtMark();
      }
    } else {
      hasEndOfStmtMark = parseEndOfStmtMark();
    }
    return ReturnStmt(keyword,
        returnValue: expr,
        source: currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseExprStmtOrBlock({bool isStatement = true}) {
    if (curTok.lexeme == lexer.lexicon.blockStart) {
      return _parseBlockStmt(id: InternalIdentifier.blockStatement);
    } else {
      if (isStatement) {
        final startTok = curTok;
        var node = parseStmt(style: ParseStyle.functionDefinition);
        if (node == null) {
          final err = HTError.unexpected(HTLocale.current.expressionStatement,
              HTLocale.current.expression, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
          node = ASTEmptyLine(
              source: currentSource,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.offset - startTok.offset);
          node.precedings.addAll(currentPrecedings);
          currentPrecedings.clear();
        }
        return node;
      } else {
        return _parseExprStmt();
      }
    }
  }

  IfExpr _parseIf({bool isStatement = true, bool requireElse = false}) {
    final keyword = match(lexer.lexicon.kIf);
    match(lexer.lexicon.groupExprStart);
    final condition = parseExpr();
    match(lexer.lexicon.groupExprEnd);
    var thenBranch = _parseExprStmtOrBlock(isStatement: isStatement);
    handlePrecedings();
    ASTNode? elseBranch;
    if (requireElse) {
      match(lexer.lexicon.kElse);
      elseBranch = _parseExprStmtOrBlock(isStatement: isStatement);
    } else {
      if (expect([lexer.lexicon.kElse], consume: true)) {
        elseBranch = _parseExprStmtOrBlock(isStatement: isStatement);
      }
    }
    return IfExpr(condition, thenBranch,
        elseBranch: elseBranch,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(lexer.lexicon.kWhile);
    match(lexer.lexicon.groupExprStart);
    final condition = parseExpr();
    match(lexer.lexicon.groupExprEnd);
    final loop =
        _parseBlockStmt(id: InternalIdentifier.whileStatement, isLoop: true);
    return WhileStmt(condition, loop,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance();
    final loop =
        _parseBlockStmt(id: InternalIdentifier.doStatement, isLoop: true);
    ASTNode? condition;
    bool hasEndOfStmtMark = false;
    if (expect([lexer.lexicon.kWhile], consume: true)) {
      match(lexer.lexicon.groupExprStart);
      condition = parseExpr();
      match(lexer.lexicon.groupExprEnd);
      hasEndOfStmtMark = parseEndOfStmtMark();
    }
    return DoStmt(loop, condition,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseForStmt() {
    final keyword = advance();
    final hasBracket = expect([lexer.lexicon.groupExprStart], consume: true);
    VarDecl? decl;
    ASTNode? condition;
    ASTNode? increment;
    bool implicitVariableDeclaration = false;
    if (config.allowImplicitVariableDeclaration && curTok is TokenIdentifier) {
      implicitVariableDeclaration = true;
    }
    String forStmtType;
    if (implicitVariableDeclaration) {
      forStmtType = peek(1).lexeme;
    } else {
      forStmtType = peek(2).lexeme;
    }
    if (forStmtType == lexer.lexicon.kIn || forStmtType == lexer.lexicon.kOf) {
      decl = _parseVarDecl(
        isMutable: curTok.lexeme != lexer.lexicon.kImmutable,
        implicitVariableDeclaration: implicitVariableDeclaration,
      );
      advance();
      final collection = parseExpr();
      if (hasBracket) {
        match(lexer.lexicon.groupExprEnd);
      }
      final loop =
          _parseBlockStmt(id: InternalIdentifier.forExpression, isLoop: true);
      return ForRangeExpr(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == lexer.lexicon.kOf,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([lexer.lexicon.endOfStatementMark], consume: false)) {
        decl = _parseVarDecl(
          isMutable: curTok.lexeme != lexer.lexicon.kImmutable,
          requireEndOfStatement: true,
          implicitVariableDeclaration: implicitVariableDeclaration,
        );
      } else {
        match(lexer.lexicon.endOfStatementMark);
      }
      if (!expect([lexer.lexicon.endOfStatementMark], consume: false)) {
        condition = parseExpr();
      }
      match(lexer.lexicon.endOfStatementMark);
      if (!expect([lexer.lexicon.groupExprEnd], consume: false)) {
        increment = parseExpr();
      }
      if (hasBracket) {
        match(lexer.lexicon.groupExprEnd);
      }
      final loop =
          _parseBlockStmt(id: InternalIdentifier.forExpression, isLoop: true);
      return ForExpr(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  SwitchStmt _parseSwitch({bool isStatement = true}) {
    final keyword = advance();
    ASTNode? condition;
    if (curTok.lexeme != lexer.lexicon.blockStart) {
      match(lexer.lexicon.groupExprStart);
      condition = parseExpr();
      match(lexer.lexicon.groupExprEnd);
    }
    final options = <ASTNode, ASTNode>{};
    ASTNode? elseBranch;
    match(lexer.lexicon.blockStart);
    // when branches are a bit complex so we didn't use [parseExprList] here.
    while (curTok.lexeme != lexer.lexicon.blockEnd &&
        curTok.lexeme != Token.endOfFile) {
      handlePrecedings();
      if (curTok.lexeme == lexer.lexicon.blockEnd && options.isNotEmpty) {
        break;
      }
      if (curTok.lexeme == lexer.lexicon.kElse) {
        advance();
        match(lexer.lexicon.switchBranchIndicator);
        elseBranch = _parseExprStmtOrBlock(isStatement: isStatement);
      } else {
        ASTNode caseExpr;
        // TODO: this part is dubious, might have edge cases that not covered
        if (peek(1).lexeme == lexer.lexicon.comma) {
          caseExpr = _handleCommaExpr(lexer.lexicon.switchBranchIndicator,
              isLocal: false);
        } else if (curTok.lexeme == lexer.lexicon.kIn) {
          caseExpr = _handleInOfExpr();
        } else {
          caseExpr = parseExpr();
        }
        match(lexer.lexicon.switchBranchIndicator);
        var caseBranch = _parseExprStmtOrBlock(isStatement: isStatement);
        options[caseExpr] = caseBranch;
      }
    }
    match(lexer.lexicon.blockEnd);
    assert(options.isNotEmpty);
    if (currentPrecedings.isNotEmpty) {
      options.values.last.succeedings = currentPrecedings;
      currentPrecedings = [];
    }
    return SwitchStmt(options, elseBranch, condition,
        isStatement: isStatement,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    List<GenericTypeParameterExpr> genericParams = [];
    if (expect([lexer.lexicon.typeListStart], consume: true)) {
      genericParams = parseExprList(
        endToken: lexer.lexicon.typeListEnd,
        parseFunction: () {
          final idTok = matchId();
          final id = IdentifierExpr.fromToken(idTok, source: currentSource);
          final param = GenericTypeParameterExpr(id,
              source: currentSource,
              line: idTok.line,
              column: idTok.column,
              offset: idTok.offset,
              length: curTok.offset - idTok.offset);
          setPrecedings(param);
          return param;
        },
      );
      match(lexer.lexicon.typeListEnd);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    final keyword = advance(); // not a keyword so don't use match
    List<IdentifierExpr> showList = [];
    if (curTok.lexeme == lexer.lexicon.importExportListStart) {
      advance();
      showList = parseExprList(
        endToken: lexer.lexicon.importExportListEnd,
        parseFunction: () {
          final idTok = matchId();
          final id = IdentifierExpr.fromToken(idTok, source: currentSource);
          setPrecedings(id);
          return id;
        },
      );
      match(lexer.lexicon.blockEnd);
      if (showList.isEmpty) {
        final err = HTError.unexpectedEmptyList(HTLocale.current.importSymbols,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors.add(err);
      }

      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance().lexeme;
      if (fromKeyword != lexer.lexicon.kFrom) {
        final err = HTError.unexpected(HTLocale.current.importStatement,
            lexer.lexicon.kFrom, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
    }
    IdentifierExpr? alias;

    void handleAlias() {
      match(lexer.lexicon.kAs);
      final aliasId = matchId();
      alias = IdentifierExpr.fromToken(aliasId, source: currentSource);
    }

    final fromPathTok = matchString();
    String fromPathRaw = fromPathTok.literal;
    String fromPath;
    bool isPreloadedModule = false;
    if (fromPathRaw.startsWith(HTResourceContext.hetuPreloadedModulesPrefix)) {
      isPreloadedModule = true;
      fromPath = fromPathRaw
          .substring(HTResourceContext.hetuPreloadedModulesPrefix.length);
      handleAlias();
    } else {
      fromPath = fromPathRaw;
      final ext = path.extension(fromPathTok.literal);
      if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
        if (showList.isNotEmpty) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors.add(err);
        }
        handleAlias();
      } else {
        if (curTok.lexeme == lexer.lexicon.kAs) {
          handleAlias();
        }
      }
    }

    final hasEndOfStmtMark = parseEndOfStmtMark();

    final stmt = ImportExportDecl(
        fromPath: fromPath,
        showList: showList,
        alias: alias,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isPreloadedModule: isPreloadedModule,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    currentModuleImports.add(stmt);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(); // not a keyword so don't use match
    late final ImportExportDecl stmt;
    // export some of the symbols from this or other source
    if (expect([lexer.lexicon.importExportListStart], consume: true)) {
      final showList = parseExprList(
        endToken: lexer.lexicon.importExportListEnd,
        parseFunction: () {
          final idTok = matchId();
          final id = IdentifierExpr.fromToken(idTok, source: currentSource);
          setPrecedings(id);
          return id;
        },
      );
      match(lexer.lexicon.blockEnd);
      // String? fromPath;
      if (curTok.lexeme == lexer.lexicon.kFrom) {
        advance();
        final fromPathTok = matchString();
        final ext = path.extension(fromPathTok.literal);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors.add(err);
        }
      }
      stmt = ImportExportDecl(
          // fromPath: fromPath,
          showList: showList,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      // if (fromPath != null) {
      //   currentModuleImports.add(stmt);
      // }
    } else if (expect([lexer.lexicon.everythingMark], consume: true)) {
      stmt = ImportExportDecl(
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final key = matchString();
      stmt = ImportExportDecl(
          fromPath: key.literal,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      currentModuleImports.add(stmt);
    }

    stmt.hasEndOfStmtMark = parseEndOfStmtMark();

    return stmt;
  }

  ASTNode _parseDeleteStmt() {
    var keyword = advance();
    final nextTok = peek(1);
    if (curTok is TokenIdentifier &&
        nextTok.lexeme != lexer.lexicon.memberGet &&
        nextTok.lexeme != lexer.lexicon.subGetStart) {
      final id = advance().lexeme;

      final hasEndOfStmtMark = parseEndOfStmtMark();
      return DeleteStmt(id,
          source: currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = parseExpr();

      final hasEndOfStmtMark = parseEndOfStmtMark();
      if (expr is MemberExpr) {
        return DeleteMemberStmt(expr.object, expr.key.id,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else if (expr is SubExpr) {
        return DeleteSubStmt(expr.object, expr.key,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else {
        final err = HTError.delete(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
        final empty = ASTEmptyLine(
            source: currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
        return empty;
      }
    }
  }

  NamespaceDecl _parseNamespaceDecl({bool isTopLevel = false}) {
    final keyword = advance();
    final idTok = matchId();
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    // final savedSurrentExplicitNamespaceId = _currentExplicitNamespaceId;
    // _currentExplicitNamespaceId = idTok.lexeme;
    final definition = _parseBlockStmt(
      id: id.id,
      sourceType: ParseStyle.namespace,
      isScriptBlock: false,
      blockStartMark: lexer.lexicon.namespaceStart,
    );
    // _currentExplicitNamespaceId = savedSurrentExplicitNamespaceId;
    return NamespaceDecl(
      id,
      definition,
      classId: _currentClassDeclaration?.id,
      isPrivate: lexer.lexicon.isPrivate(id.id),
      isTopLevel: isTopLevel,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.end - keyword.offset,
    );
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isTopLevel = false}) {
    final keyword = advance();
    final idTok = matchId();
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    final genericParameters = _getGenericParams();
    match(lexer.lexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(
      id,
      value,
      classId: classId,
      genericTypeParameters: genericParameters,
      isPrivate: lexer.lexicon.isPrivate(id.id),
      isTopLevel: isTopLevel,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.offset - keyword.offset,
    );
  }

  VarDecl _parseVarDecl({
    String? classId,
    bool isField = false,
    // bool isOverrided = false,
    bool isExternal = false,
    bool isStatic = false,
    // bool isConst = false,
    bool isMutable = false,
    bool isTopLevel = false,
    bool lateFinalize = false,
    bool lateInitialize = false,
    ASTNode? additionalInitializer,
    bool requireEndOfStatement = false,
    bool implicitVariableDeclaration = false,
  }) {
    Token? keyword;
    if (!implicitVariableDeclaration) {
      keyword = advance();
    }
    final idTok = matchId();
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    String? internalName;
    if (classId != null && isExternal) {
      // if (!(_currentClass!.isExternal) && !isStatic) {
      //   final err = HTError.externalMember(
      //       filename: currrentFileName,
      //       line: keyword.line,
      //       column: keyword.column,
      //       offset: curTok.offset,
      //       length: curTok.length);
      //   errors.add(err);
      // }
      internalName = '$classId.${idTok.lexeme}';
    }
    TypeExpr? declType;
    if (expect([lexer.lexicon.typeIndicator], consume: true)) {
      declType = _parseTypeExpr();
    }
    ASTNode? initializer;
    if (!lateFinalize) {
      // if (isConst) {
      //   if (curTok.lexeme != lexer.lexicon.assign) {
      //     final err = HTError.constMustInit(id.id,
      //         filename: currrentFileName,
      //         line: curTok.line,
      //         column: curTok.column,
      //         offset: curTok.offset,
      //         length: curTok.length);
      //     errors.add(err);
      //   } else {
      //     match(lexer.lexicon.assign);
      //     initializer = parseExpr();
      //   }
      // } else {
      if (expect([lexer.lexicon.assign], consume: true)) {
        initializer = parseExpr();
      } else {
        initializer = additionalInitializer;
      }
      // }
    }
    bool hasEndOfStmtMark = parseEndOfStmtMark(required: requireEndOfStatement);
    return VarDecl(
      id,
      internalName: internalName,
      classId: classId,
      declType: declType,
      initializer: initializer,
      hasEndOfStmtMark: hasEndOfStmtMark,
      isPrivate: lexer.lexicon.isPrivate(id.id),
      isField: isField,
      isExternal: isExternal,
      isStatic: // isConst &&
          classId != null ? true : isStatic,
      // isConst: isConst,
      isMutable: //!isConst &&
          isMutable,
      isTopLevel: isTopLevel,
      lateFinalize: lateFinalize,
      lateInitialize: lateInitialize,
      source: currentSource,
      line: keyword?.line ?? idTok.line,
      column: keyword?.column ?? idTok.column,
      offset: keyword?.offset ?? idTok.offset,
      length: curTok.offset - (keyword?.offset ?? idTok.offset),
    );
  }

  //TODO: 解构赋值还原每个id为单独的decl比较好，因为涉及到私有性。
  DestructuringDecl _parseDestructuringDecl(
      {bool isTopLevel = false, bool isMutable = false}) {
    final keyword = advance(2);
    final ids = <IdentifierExpr, TypeExpr?>{};
    bool isVector = false;
    String endMark;
    if (peek(-1).lexeme == lexer.lexicon.listStart) {
      endMark = lexer.lexicon.listEnd;
      isVector = true;
    } else {
      endMark = lexer.lexicon.blockEnd;
    }
    // declarations are a bit complex so we didn't use [parseExprList] here.
    while (curTok.lexeme != endMark && curTok.lexeme != Token.endOfFile) {
      handlePrecedings();
      final idTok = matchId();
      final id = IdentifierExpr.fromToken(idTok, source: currentSource);
      setPrecedings(id);
      TypeExpr? declType;
      if (expect([lexer.lexicon.typeIndicator], consume: true)) {
        declType = _parseTypeExpr();
      }
      ids[id] = declType;
      handleTrailing(declType ?? id, endMarkForCommaExpressions: endMark);
    }
    match(endMark);
    match(lexer.lexicon.assign);
    final initializer = parseExpr();
    final hasEndOfStmtMark = parseEndOfStmtMark();
    return DestructuringDecl(
      ids: ids,
      isVector: isVector,
      initializer: initializer,
      isTopLevel: isTopLevel,
      isMutable: isMutable,
      hasEndOfStmtMark: hasEndOfStmtMark,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.offset - keyword.offset,
    );
  }

  FuncDecl _parseFunction({
    FunctionCategory category = FunctionCategory.normal,
    String? classId,
    // bool hasKeyword = true,
    bool isAsync = false,
    bool isField = false,
    // bool isOverrided = false,
    bool isExternal = false,
    bool isStatic = false,
    bool isConst = false,
    bool isTopLevel = false,
  }) {
    if (isAsync) {
      assert(category == FunctionCategory.normal ||
          // category == FunctionCategory.method ||
          category == FunctionCategory.literal);
    }

    final startTok = curTok;

    // there are multiple possible keyword for function
    switch (category) {
      case FunctionCategory.normal:
        match2(lexer.lexicon.kFunctions);
      case FunctionCategory.constructor:
        match2(lexer.lexicon.kConstructors);
      case FunctionCategory.factoryConstructor:
        match(lexer.lexicon.kFactory);
      case FunctionCategory.getter:
        match(lexer.lexicon.kGet);
      case FunctionCategory.setter:
        match(lexer.lexicon.kSet);
      case FunctionCategory.literal:
        if (lexer.lexicon.kFunctions.contains(curTok.lexeme)) {
          advance();
        }
    }

    // handle external type id
    String? externalTypeId;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([lexer.lexicon.listStart], consume: true)) {
        externalTypeId = matchId().lexeme;
        match(lexer.lexicon.listEnd);
      }
    }

    // to distinguish getter and setter, and to give default constructor a name
    Token? id;
    late String internalName;
    switch (category) {
      case FunctionCategory.factoryConstructor:
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok is TokenIdentifier) {
          id = advance();
        }
        internalName = (id == null)
            ? InternalIdentifier.defaultConstructor
            : '${InternalIdentifier.namedConstructorPrefix}$id';
      case FunctionCategory.literal:
        if (curTok is TokenIdentifier) {
          id = advance();
        }
        internalName = (id == null)
            ? '${InternalIdentifier.anonymousFunction}${HTParser.anonymousFunctionIndex++}'
            : id.lexeme;
      case FunctionCategory.getter:
        id = matchId();
        internalName = '${InternalIdentifier.getter}$id';
      case FunctionCategory.setter:
        id = matchId();
        internalName = '${InternalIdentifier.setter}$id';
      default:
        id = matchId();
        internalName = id.lexeme;
    }
    final genericTypeParameters = _getGenericParams();
    var isVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    List<ParamDecl> paramDecls = [];
    var hasParamDecls = false;
    if (expect([lexer.lexicon.functionParameterStart], consume: true)) {
      if (category == FunctionCategory.getter &&
          curTok.lexeme != lexer.lexicon.functionParameterEnd) {
        final err = HTError.getterParam(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }

      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      bool allowVariadic = true;

      ParamDecl parseParam() {
        bool isParamVariadic = false;
        if (allowVariadic) {
          isParamVariadic = expect([lexer.lexicon.variadicArgs], consume: true);
          if (isVariadic && isParamVariadic) {
            final err = HTError.unexpected(
                HTLocale.current.functionTypeExpression,
                HTLocale.current.paramTypeExpression,
                lexer.lexicon.variadicArgs,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
          }
          isVariadic = isParamVariadic;
        }
        TypeExpr? paramDeclType;
        IdentifierExpr paramSymbol;
        bool hasThisInitializingSyntax = false;
        if (category == FunctionCategory.constructor) {
          hasThisInitializingSyntax =
              expect([lexer.lexicon.kThis], consume: true);
        }
        if (hasThisInitializingSyntax) {
          hasThisInitializingSyntax = true;
          match(lexer.lexicon.memberGet);
        }
        final paramId = matchId();
        paramSymbol = IdentifierExpr.fromToken(paramId, source: currentSource);

        if (!hasThisInitializingSyntax) {
          if (expect([lexer.lexicon.typeIndicator], consume: true)) {
            paramDeclType = _parseTypeExpr();
          }
        }

        ASTNode? initializer;
        if (expect([lexer.lexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = parseExpr();
            if (initializer.isAwait) {
              final err = HTError.awaitExpression(
                  filename: currrentFileName,
                  line: initializer.line,
                  column: initializer.column,
                  offset: initializer.offset,
                  length: initializer.length);
              errors.add(err);
            }
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                filename: currrentFileName,
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
            isVariadic: isParamVariadic,
            isOptional: isOptional,
            isNamed: isNamed,
            isInitialization: hasThisInitializingSyntax,
            source: currentSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);
        setPrecedings(param);
        return param;
      }

      while (curTok.lexeme != lexer.lexicon.functionParameterEnd &&
          curTok.lexeme != Token.endOfFile) {
        handlePrecedings();
        if (curTok.lexeme == lexer.lexicon.functionParameterEnd) {
          // TODO: store comments within empty function parameter list
          break;
        }
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional &&
            !isNamed &&
            expect([lexer.lexicon.functionPositionalParameterStart],
                consume: true)) {
          isOptional = true;
          final params = parseExprList(
            endToken: lexer.lexicon.functionPositionalParameterEnd,
            parseFunction: parseParam,
          );
          maxArity += params.length;
          match(lexer.lexicon.functionPositionalParameterEnd);
          paramDecls.addAll(params);
        }
        //检查命名参数, 根据是否有花括号判断
        else if (!isOptional &&
            !isNamed &&
            expect([lexer.lexicon.functionNamedParameterStart],
                consume: true)) {
          isNamed = true;
          allowVariadic = false;
          final params = parseExprList(
            endToken: lexer.lexicon.functionNamedParameterEnd,
            parseFunction: parseParam,
          );
          match(lexer.lexicon.functionNamedParameterEnd);
          paramDecls.addAll(params);
        } else {
          ++minArity;
          ++maxArity;
          final param = parseParam();
          paramDecls.add(param);
          handleTrailing(param,
              endMarkForCommaExpressions: lexer.lexicon.functionParameterEnd);
        }
      }
      final endTok = match(lexer.lexicon.functionParameterEnd);
      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: currrentFileName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors.add(err);
      }
    }

    TypeExpr? returnType;
    RedirectingConstructorCallExpr? redirectingCtorCallExpr;
    // the return value type declaration
    if (expect([lexer.lexicon.returnTypeIndicator], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(HTLocale.current.function,
            HTLocale.current.functionDefinition, HTLocale.current.returnType,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([lexer.lexicon.constructorInitializationListIndicator],
        consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.unexpected(
            HTLocale.current.function,
            lexer.lexicon.constructorInitializationListIndicator,
            lastTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      final ctorCallee = advance();
      if (!lexer.lexicon.redirectingConstructorCallKeywords
          .contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(HTLocale.current.function,
            HTLocale.current.constructorCall, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors.add(err);
      }
      Token? ctorKey;
      if (expect([lexer.lexicon.memberGet], consume: true)) {
        ctorKey = matchId();
        match(lexer.lexicon.groupExprStart);
      } else {
        match(lexer.lexicon.groupExprStart);
      }
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      redirectingCtorCallExpr = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee, source: currentSource),
          positionalArgs,
          namedArgs,
          key: ctorKey != null
              ? IdentifierExpr.fromToken(ctorKey, source: currentSource)
              : null,
          source: currentSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    if (isAsync == false) {
      if (category == FunctionCategory.normal ||
          // category == FunctionCategory.method ||
          category == FunctionCategory.literal) {
        if (expect([lexer.lexicon.kAsync], consume: true)) {
          isAsync = true;
        }
      }
    }

    final savedCurrentFunctionDeclaration = _currentFunctionDeclaration;
    _currentFunctionDeclaration = HTFunctionDeclaration(
      internalName: internalName,
      id: id?.lexeme,
      classId: classId,
      isPrivate: lexer.lexicon.isPrivate(id?.lexeme),
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isTopLevel: isTopLevel,
      category: category,
      externalTypeId: externalTypeId,
      // genericTypeParameters: genericTypeParameters,
      hasParamDecls: hasParamDecls,
      isAsync: isAsync,
      isField: isField,
      // isField: isField,
      // isAbstract: definition != null,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
    );

    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    ASTNode? definition;
    if (curTok.lexeme == lexer.lexicon.functionStart) {
      definition = _parseBlockStmt(
        id: HTLocale.current.functionCall,
        blockStartMark: lexer.lexicon.functionStart,
      );
    } else if (expect([lexer.lexicon.singleLineFunctionIndicator],
        consume: true)) {
      isExpressionBody = true;
      definition = parseExpr();
      hasEndOfStmtMark = parseEndOfStmtMark();
    } else if (expect([lexer.lexicon.assign], consume: true)) {
      final err = HTError.unsupported(
          HTLocale.current.redirectingFunctionDefinition,
          kHetuVersion.toString(),
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_currentClassDeclaration?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      hasEndOfStmtMark = parseEndOfStmtMark();
    }
    final funcDecl = FuncDecl(
      internalName,
      id: id != null
          ? IdentifierExpr.fromToken(id, source: currentSource)
          : null,
      classId: classId,
      genericTypeParameters: genericTypeParameters,
      externalTypeId: externalTypeId,
      redirectingConstructorCall: redirectingCtorCallExpr,
      hasParamDecls: hasParamDecls,
      paramDecls: paramDecls,
      returnType: returnType,
      minArity: minArity,
      maxArity: maxArity,
      isExpressionBody: isExpressionBody,
      hasEndOfStmtMark: hasEndOfStmtMark,
      definition: definition,
      isPrivate: lexer.lexicon.isPrivate(id?.lexeme),
      isAsync: isAsync,
      isField: isField,
      // isField: isField,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isVariadic: isVariadic,
      isTopLevel: isTopLevel,
      category: category,
      source: currentSource,
      line: startTok.line,
      column: startTok.column,
      offset: startTok.offset,
      length: curTok.offset - startTok.offset,
    );
    _currentFunctionDeclaration = savedCurrentFunctionDeclaration;
    return funcDecl;
  }

  ClassDecl _parseClassDecl({
    String? classId,
    bool isExternal = false,
    bool isAbstract = false,
    bool isTopLevel = false,
    bool lateResolve = true,
  }) {
    final keyword = match(lexer.lexicon.kClass);
    if (_currentClassDeclaration != null &&
        _currentClassDeclaration!.isNested) {
      final err = HTError.nestedClass(
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors.add(err);
    }
    final id = matchId();
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (curTok.lexeme == lexer.lexicon.kExtends) {
      advance();
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      superClassType = _parseTypeExpr();
    }
    final savedClass = _currentClassDeclaration;
    _currentClassDeclaration = HTClassDeclaration(
      id: id.lexeme,
      classId: classId,
      isExternal: isExternal,
      isAbstract: isAbstract,
    );
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
      sourceType: ParseStyle.classDefinition,
      isScriptBlock: false,
      id: InternalIdentifier.classDeclaration,
      blockStartMark: lexer.lexicon.classStart,
    );
    final classDecl = ClassDecl(
      IdentifierExpr.fromToken(id, source: currentSource),
      definition,
      genericTypeParameters: genericParameters,
      superType: superClassType,
      isPrivate: lexer.lexicon.isPrivate(id.lexeme),
      isExternal: isExternal,
      isAbstract: isAbstract,
      isTopLevel: isTopLevel,
      hasUserDefinedConstructor: _hasUserDefinedConstructor,
      lateResolve: lateResolve,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.offset - keyword.offset,
    );
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _currentClassDeclaration = savedClass;

    return classDecl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(lexer.lexicon.kEnum);
    final id = matchId();
    var enumerations = <IdentifierExpr>[];
    bool isPreviousItemEndedWithComma = false;
    bool hasEndOfStmtMark = false;
    if (expect([lexer.lexicon.enumStart], consume: true)) {
      while (curTok.lexeme != lexer.lexicon.blockEnd &&
          curTok.lexeme != Token.endOfFile) {
        final hasPrecedingComments = handlePrecedings();
        if (hasPrecedingComments &&
            !isPreviousItemEndedWithComma &&
            enumerations.isNotEmpty) {
          enumerations.last.succeedings.addAll(currentPrecedings);
          break;
        }
        if ((curTok.lexeme == lexer.lexicon.blockEnd) ||
            (curTok.lexeme == Token.endOfFile)) {
          break;
        }
        isPreviousItemEndedWithComma = false;
        final enumIdTok = matchId();
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: currentSource);
        setPrecedings(enumId);
        handleTrailing(enumId,
            endMarkForCommaExpressions: lexer.lexicon.blockEnd);
        enumerations.add(enumId);
      }
      match(lexer.lexicon.enumEnd);
    } else {
      hasEndOfStmtMark =
          expect([lexer.lexicon.endOfStatementMark], consume: true);
    }
    final enumDecl = EnumDecl(
      IdentifierExpr.fromToken(id, source: currentSource),
      enumerations,
      isPrivate: lexer.lexicon.isPrivate(id.lexeme),
      isExternal: isExternal,
      isTopLevel: isTopLevel,
      hasEndOfStmtMark: hasEndOfStmtMark,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.offset - keyword.offset,
    );

    return enumDecl;
  }

  StructDecl _parseStructDecl({bool isTopLevel = false}) {
    //, bool lateInitialize = true}) {
    final keyword = match(lexer.lexicon.kStruct);
    final idTok = matchId();
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    IdentifierExpr? prototypeId;
    List<IdentifierExpr> mixinIds = [];
    if (expect([lexer.lexicon.kExtends], consume: true)) {
      final prototypeIdTok = matchId();
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors.add(err);
      }
      prototypeId =
          IdentifierExpr.fromToken(prototypeIdTok, source: currentSource);
    } else if (expect([lexer.lexicon.kWith], consume: true)) {
      while (curTok.lexeme != lexer.lexicon.structStart &&
          curTok.lexeme != Token.endOfFile) {
        final mixinIdTok = matchId();
        if (mixinIdTok.lexeme == id.id) {
          final err = HTError.extendsSelf(
              filename: currrentFileName,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
          errors.add(err);
        }
        final mixinId =
            IdentifierExpr.fromToken(mixinIdTok, source: currentSource);
        handleTrailing(mixinId,
            endMarkForCommaExpressions: lexer.lexicon.structStart);
        mixinIds.add(mixinId);
      }
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <ASTNode>[];
    final startTok = match(lexer.lexicon.structStart);
    while (curTok.lexeme != lexer.lexicon.structEnd &&
        curTok.lexeme != Token.endOfFile) {
      handlePrecedings();
      if (curTok.lexeme == lexer.lexicon.structEnd) break;
      final stmt = parseStmt(style: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(lexer.lexicon.structEnd);
    if (definition.isEmpty) {
      final empty = ASTEmptyLine(
          source: currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedings.addAll(currentPrecedings);
      currentPrecedings.clear();
      definition.add(empty);
    }
    _currentStructId = savedStructId;
    final structDecl = StructDecl(
      id, definition,
      prototypeId: prototypeId,
      mixinIds: mixinIds,
      isPrivate: lexer.lexicon.isPrivate(id.id),
      isTopLevel: isTopLevel,
      // lateInitialize: lateInitialize,
      source: currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.offset - keyword.offset,
    );
    return structDecl;
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(lexer.lexicon.kStruct);
      if (hasKeyword && expect([lexer.lexicon.kExtends], consume: true)) {
        final idTok = matchId();
        prototypeId = IdentifierExpr.fromToken(idTok, source: currentSource);
      }
    }
    prototypeId ??= IdentifierExpr(lexer.lexicon.globalPrototypeId);
    final structBlockStartTok = match(lexer.lexicon.structStart);
    final fields = <StructObjField>[];
    // struct are a bit complex so we didn't use [parseExprList] here.
    while (curTok.lexeme != lexer.lexicon.structEnd &&
        curTok.lexeme != Token.endOfFile) {
      handlePrecedings();
      if (curTok.lexeme == lexer.lexicon.structEnd) {
        break;
      }
      if (curTok is TokenIdentifier || curTok is TokenStringLiteral) {
        final keyTok = advance();
        StructObjField field;
        if (curTok.lexeme == lexer.lexicon.comma ||
            curTok.lexeme == lexer.lexicon.structEnd) {
          final id = IdentifierExpr.fromToken(keyTok, source: currentSource);
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: currentSource,
              ),
              fieldValue: id);
          setPrecedings(field);
        } else {
          match(lexer.lexicon.structValueIndicator);
          final value = parseExpr();
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: currentSource,
              ),
              fieldValue: value);
        }
        fields.add(field);
        handleTrailing(field,
            endMarkForCommaExpressions: lexer.lexicon.structEnd);
      } else if (curTok.lexeme == lexer.lexicon.spreadSyntax) {
        advance();
        final value = parseExpr();
        final field = StructObjField(fieldValue: value);
        fields.add(field);
        fields.add(field);
        handleTrailing(field,
            endMarkForCommaExpressions: lexer.lexicon.structEnd);
      } else {
        final errTok = advance();
        final err = HTError.structMemberId(curTok.lexeme,
            filename: currrentFileName,
            line: errTok.line,
            column: errTok.column,
            offset: errTok.offset,
            length: errTok.length);
        errors.add(err);
      }
    }
    // if (fields.isEmpty) {
    //   final empty = StructObjField(
    //       source: currentSource,
    //       line: curTok.line,
    //       column: curTok.column,
    //       offset: curTok.offset,
    //       length: curTok.offset - structBlockStartTok.offset);
    //   setPrecedings(empty);
    // }
    match(lexer.lexicon.structEnd);
    return StructObjExpr(
      fields,
      prototypeId: prototypeId,
      source: currentSource,
      line: structBlockStartTok.line,
      column: structBlockStartTok.column,
      offset: structBlockStartTok.offset,
      length: curTok.offset - structBlockStartTok.offset,
    );
  }
}
