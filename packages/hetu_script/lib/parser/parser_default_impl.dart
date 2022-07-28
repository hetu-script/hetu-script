import 'package:path/path.dart' as path;

import 'parser.dart';
import 'token.dart';
import '../lexer/lexicon_default_impl.dart';
import '../error/error.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../grammar/constant.dart';
import '../declaration/class/class_declaration.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';

/// Default parser implementation used by Hetu.
class HTDefaultParser extends HTParser {
  @override
  String get name => 'default';

  HTDefaultParser({
    super.config,
  }) : super(lexicon: HTDefaultLexicon());

  bool get _isWithinModuleNamespace {
    if (_currentFunctionCategory != null) {
      return false;
    } else if (currentSource != null) {
      if (currentSource!.type == HTResourceType.hetuModule) {
        return true;
      }
    }
    return false;
  }

  // String? _currentExplicitNamespaceId;
  HTClassDeclaration? _currentClassDeclaration;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;
  bool _isLegalLeftValue = false;
  bool _hasUserDefinedConstructor = false;
  bool _isInLoop = false;

  @override
  void resetFlags() {
    _currentClassDeclaration = null;
    _currentFunctionCategory = null;
    _currentStructId = null;
    _isLegalLeftValue = false;
    _hasUserDefinedConstructor = false;
    _isInLoop = false;
  }

  @override
  ASTNode? parseStmt({required ParseStyle style}) {
    handlePrecedings();

    // if (_handlePrecedingCommentsOrEmptyLines()) {
    //   return null;
    // }

    // handle emtpy statement is a must because automatic semicolon insertion.
    if (curTok.type == lexicon.endOfStatementMark) {
      advance();
      return null;
    }

    if (curTok.type == Semantic.endOfFile) {
      return null;
    }

    // save preceding comments because those might change during expression parsing.
    final savedPrecedings = savePrecedings();

    // if (curTok is TokenEmptyLine) {
    //   final empty = advance();
    //   final emptyStmt = ASTEmptyLine(
    //       line: empty.line, column: empty.column, offset: empty.offset);
    //   emptyStmt.precedingComments = precedingComments;
    //   return emptyStmt;
    // }

    ASTNode stmt;

    switch (style) {
      case ParseStyle.script:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexicon.kNamespace) {
          stmt = _parseNamespaceDecl(isTopLevel: true);
        } else if (curTok.type == lexicon.kExternal) {
          advance();
          if (curTok.type == lexicon.kAbstract) {
            advance();
            stmt = _parseClassDecl(
                isAbstract: true, isExternal: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
          } else if (lexicon.variableDeclarationKeywords
              .contains(curTok.type)) {
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
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(isExternal: true, isTopLevel: true);
          } else {
            final err = HTError.unexpected(
                lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
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
        } else if (curTok.type == lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(
              isAbstract: true, isTopLevel: true, lateResolve: false);
        } else if (curTok.type == lexicon.kClass) {
          stmt = _parseClassDecl(isTopLevel: true, lateResolve: false);
        } else if (curTok.type == lexicon.kEnum) {
          stmt = _parseEnumDecl(isTopLevel: true);
        } else if (curTok.type == lexicon.kVar) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl(isTopLevel: true, isMutable: true);
          } else {
            stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
          }
        } else if (curTok.type == lexicon.kFinal) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl(isTopLevel: true);
          } else {
            stmt = _parseVarDecl(isTopLevel: true);
          }
        } else if (curTok.type == lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kConst) {
          stmt = _parseVarDecl(isConst: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kFun) {
          if (expect([lexicon.kFun, Semantic.identifier]) ||
              expect([
                lexicon.kFun,
                lexicon.externalFunctionTypeDefStart,
                Semantic.identifier,
                lexicon.externalFunctionTypeDefEnd,
                Semantic.identifier
              ])) {
            stmt = _parseFunction(isTopLevel: true);
          } else {
            stmt = _parseFunction(
                category: FunctionCategory.literal, isTopLevel: true);
          }
        }
        // else if (curTok.type == lexicon.kAsync) {
        //   if (expect([lexicon.kAsync, Semantic.identifier]) ||
        //       expect([
        //         lexicon.kFun,
        //         lexicon.externalFunctionTypeDefStart,
        //         Semantic.identifier,
        //         lexicon.externalFunctionTypeDefEnd,
        //         Semantic.identifier
        //       ])) {
        //     stmt = _parseFunction(isAsync: true, isTopLevel: true);
        //   } else {
        //     stmt = _parseFunction(
        //         category: FunctionCategory.literal,
        //         isAsync: true,
        //         isTopLevel: true);
        //   }
        // }
        else if (curTok.type == lexicon.kStruct) {
          stmt =
              _parseStructDecl(isTopLevel: true); // , lateInitialize: false);
        } else if (curTok.type == lexicon.kDelete) {
          stmt = _parseDeleteStmt();
        } else if (curTok.type == lexicon.kIf) {
          stmt = _parseIf();
        } else if (curTok.type == lexicon.kWhile) {
          stmt = _parseWhileStmt();
        } else if (curTok.type == lexicon.kDo) {
          stmt = _parseDoStmt();
        } else if (curTok.type == lexicon.kFor) {
          stmt = _parseForStmt();
        } else if (curTok.type == lexicon.kWhen) {
          stmt = _parseWhen();
        } else if (curTok.type == lexicon.kAssert) {
          stmt = _parseAssertStmt();
        } else if (curTok.type == lexicon.kThrow) {
          stmt = _parseThrowStmt();
        } else {
          stmt = _parseExprStmt();
        }
        break;
      case ParseStyle.module:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else if (curTok.lexeme == lexicon.kNamespace) {
          stmt = _parseNamespaceDecl(isTopLevel: true);
        } else if (curTok.type == lexicon.kExternal) {
          advance();
          if (curTok.type == lexicon.kAbstract) {
            advance();
            if (curTok.type != lexicon.kClass) {
              final err = HTError.unexpected(
                  lexicon.kAbstract, Semantic.classDeclaration, curTok.lexeme,
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
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(isExternal: true, isTopLevel: true);
          } else if (lexicon.variableDeclarationKeywords
              .contains(curTok.type)) {
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
            final err = HTError.unexpected(
                lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
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
        } else if (curTok.type == lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kClass) {
          stmt = _parseClassDecl(isTopLevel: true);
        } else if (curTok.type == lexicon.kEnum) {
          stmt = _parseEnumDecl(isTopLevel: true);
        } else if (curTok.type == lexicon.kVar) {
          stmt = _parseVarDecl(
              isMutable: true, isTopLevel: true, lateInitialize: true);
        } else if (curTok.type == lexicon.kFinal) {
          stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kConst) {
          stmt = _parseVarDecl(isConst: true, isTopLevel: true);
        } else if (curTok.type == lexicon.kFun) {
          stmt = _parseFunction(isTopLevel: true);
        } else if (curTok.type == lexicon.kStruct) {
          stmt = _parseStructDecl(isTopLevel: true);
        } else {
          final err = HTError.unexpected(
              Semantic.declStmt, Semantic.declStmt, curTok.lexeme,
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
        break;
      case ParseStyle.namespace:
        if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else if (curTok.lexeme == lexicon.kNamespace) {
          stmt = _parseNamespaceDecl();
        } else if (curTok.type == lexicon.kExternal) {
          advance();
          if (curTok.type == lexicon.kAbstract) {
            advance();
            if (curTok.type != lexicon.kClass) {
              final err = HTError.unexpected(
                  lexicon.kAbstract, Semantic.classDeclaration, curTok.lexeme,
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
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(isExternal: true);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl(isExternal: true);
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(isExternal: true);
          } else if (lexicon.variableDeclarationKeywords
              .contains(curTok.type)) {
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
            final err = HTError.unexpected(
                lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
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
        } else if (curTok.type == lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(
              isAbstract: true, lateResolve: _isWithinModuleNamespace);
        } else if (curTok.type == lexicon.kClass) {
          stmt = _parseClassDecl(lateResolve: _isWithinModuleNamespace);
        } else if (curTok.type == lexicon.kEnum) {
          stmt = _parseEnumDecl();
        } else if (curTok.type == lexicon.kVar) {
          stmt = _parseVarDecl(
              isMutable: true, lateInitialize: _isWithinModuleNamespace);
        } else if (curTok.type == lexicon.kFinal) {
          stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace);
        } else if (curTok.type == lexicon.kConst) {
          stmt = _parseVarDecl(isConst: true);
        } else if (curTok.type == lexicon.kFun) {
          stmt = _parseFunction();
        } else if (curTok.type == lexicon.kStruct) {
          stmt = _parseStructDecl();
        } else {
          final err = HTError.unexpected(
              Semantic.declStmt, Semantic.declStmt, curTok.lexeme,
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
        break;
      case ParseStyle.classDefinition:
        final isOverrided = expect([lexicon.kOverride], consume: true);
        final isExternal = expect([lexicon.kExternal], consume: true) ||
            (_currentClassDeclaration?.isExternal ?? false);
        final isStatic = expect([lexicon.kStatic], consume: true);
        if (curTok.lexeme == lexicon.kType) {
          if (isExternal) {
            final err = HTError.external(Semantic.typeAliasDeclaration,
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
          if (curTok.type == lexicon.kVar) {
            stmt = _parseVarDecl(
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          } else if (curTok.type == lexicon.kFinal) {
            stmt = _parseVarDecl(
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic,
                lateInitialize: true);
          } else if (curTok.type == lexicon.kLate) {
            stmt = _parseVarDecl(
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic,
                lateFinalize: true);
          } else if (curTok.type == lexicon.kConst) {
            if (isStatic) {
              stmt = _parseVarDecl(
                  isConst: true, classId: _currentClassDeclaration?.id);
            } else {
              final err = HTError.external(Semantic.typeAliasDeclaration,
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
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(
                category: FunctionCategory.method,
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          }
          // else if (curTok.type == lexicon.kAsync) {
          //   if (isExternal) {
          //     final err = HTError.external(Semantic.asyncFunction,
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
          //         category: FunctionCategory.method,
          //         classId: _currentClassDeclaration?.id,
          //         isAsync: true,
          //         isOverrided: isOverrided,
          //         isExternal: isExternal,
          //         isStatic: isStatic);
          //   }
          // }
          else if (curTok.type == lexicon.kGet) {
            stmt = _parseFunction(
                category: FunctionCategory.getter,
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.type == lexicon.kSet) {
            stmt = _parseFunction(
                category: FunctionCategory.setter,
                classId: _currentClassDeclaration?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.type == lexicon.kConstruct) {
            if (isStatic) {
              final err = HTError.unexpected(
                  lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
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
              final err = HTError.external(Semantic.ctorFunction,
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
          } else if (curTok.type == lexicon.kFactory) {
            if (isStatic) {
              final err = HTError.unexpected(
                  lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
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
              final err = HTError.external(Semantic.factory,
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
            final err = HTError.unexpected(
                Semantic.classDefinition, Semantic.declStmt, curTok.lexeme,
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
        break;
      case ParseStyle.structDefinition:
        final isExternal = expect([lexicon.kExternal], consume: true);
        final isStatic = expect([lexicon.kStatic], consume: true);
        if (curTok.type == lexicon.kVar) {
          stmt = _parseVarDecl(
              classId: _currentStructId,
              isField: true,
              isExternal: isExternal,
              isMutable: true,
              isStatic: isStatic,
              lateInitialize: true);
        } else if (curTok.type == lexicon.kFinal) {
          stmt = _parseVarDecl(
              classId: _currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic,
              lateInitialize: true);
        } else if (curTok.type == lexicon.kFun) {
          stmt = _parseFunction(
              category: FunctionCategory.method,
              classId: _currentStructId,
              isExternal: isExternal,
              isField: true,
              isStatic: isStatic);
        }
        // else if (curTok.type == lexicon.kAsync) {
        //   if (isExternal) {
        //     final err = HTError.external(Semantic.asyncFunction,
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
        //         category: FunctionCategory.method,
        //         classId: _currentStructId,
        //         isAsync: true,
        //         isField: true,
        //         isExternal: isExternal,
        //         isStatic: isStatic);
        //   }
        // }
        else if (curTok.type == lexicon.kGet) {
          stmt = _parseFunction(
              category: FunctionCategory.getter,
              classId: _currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic);
        } else if (curTok.type == lexicon.kSet) {
          stmt = _parseFunction(
              category: FunctionCategory.setter,
              classId: _currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic);
        } else if (curTok.type == lexicon.kConstruct) {
          if (isStatic) {
            final err = HTError.unexpected(
                lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
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
            final err = HTError.external(Semantic.ctorFunction,
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
                isField: true);
          }
        } else {
          final err = HTError.unexpected(
              Semantic.structDefinition, Semantic.declStmt, curTok.lexeme,
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
        break;
      case ParseStyle.functionDefinition:
        if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else if (curTok.lexeme == lexicon.kNamespace) {
          stmt = _parseNamespaceDecl();
        } else if (curTok.type == lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(isAbstract: true, lateResolve: false);
        } else if (curTok.type == lexicon.kClass) {
          stmt = _parseClassDecl(lateResolve: false);
        } else if (curTok.type == lexicon.kEnum) {
          stmt = _parseEnumDecl();
        } else if (curTok.type == lexicon.kVar) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl(isMutable: true);
          } else {
            stmt = _parseVarDecl(isMutable: true);
          }
        } else if (curTok.type == lexicon.kFinal) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl();
          } else {
            stmt = _parseVarDecl();
          }
        } else if (curTok.type == lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true);
        } else if (curTok.type == lexicon.kConst) {
          stmt = _parseVarDecl(isConst: true);
        } else if (curTok.type == lexicon.kFun) {
          if (expect([lexicon.kFun, Semantic.identifier]) ||
              expect([
                lexicon.kFun,
                lexicon.externalFunctionTypeDefStart,
                Semantic.identifier,
                lexicon.externalFunctionTypeDefEnd,
                Semantic.identifier
              ])) {
            stmt = _parseFunction();
          } else {
            stmt = _parseFunction(category: FunctionCategory.literal);
          }
        }
        // else if (curTok.type == lexicon.kAsync) {
        //   if (expect([lexicon.kAsync, Semantic.identifier]) ||
        //       expect([
        //         lexicon.kFun,
        //         lexicon.externalFunctionTypeDefStart,
        //         Semantic.identifier,
        //         lexicon.externalFunctionTypeDefEnd,
        //         Semantic.identifier
        //       ])) {
        //     stmt = _parseFunction(isAsync: true);
        //   } else {
        //     stmt = _parseFunction(
        //         category: FunctionCategory.literal, isAsync: true);
        //   }
        // }
        else if (curTok.type == lexicon.kStruct) {
          stmt = _parseStructDecl(); // (lateInitialize: false);
        } else if (curTok.type == lexicon.kDelete) {
          stmt = _parseDeleteStmt();
        } else if (curTok.type == lexicon.kIf) {
          stmt = _parseIf();
        } else if (curTok.type == lexicon.kWhile) {
          stmt = _parseWhileStmt();
        } else if (curTok.type == lexicon.kDo) {
          stmt = _parseDoStmt();
        } else if (curTok.type == lexicon.kFor) {
          stmt = _parseForStmt();
        } else if (curTok.type == lexicon.kWhen) {
          stmt = _parseWhen();
        } else if (curTok.type == lexicon.kAssert) {
          stmt = _parseAssertStmt();
        } else if (curTok.type == lexicon.kThrow) {
          stmt = _parseThrowStmt();
        } else if (curTok.type == lexicon.kBreak) {
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
          final hasEndOfStmtMark =
              expect([lexicon.endOfStatementMark], consume: true);
          stmt = BreakStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.type == lexicon.kContinue) {
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
          final hasEndOfStmtMark =
              expect([lexicon.endOfStatementMark], consume: true);
          stmt = ContinueStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.type == lexicon.kReturn) {
          if (_currentFunctionCategory == null ||
              _currentFunctionCategory == FunctionCategory.constructor) {
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
        break;
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
    final keyword = match(lexicon.kAssert);
    match(lexicon.groupExprStart);
    final expr = parseExpr();
    match(lexicon.groupExprEnd);
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
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
    final keyword = match(lexicon.kThrow);
    final message = parseExpr();
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
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
    while (curTok.type != lexicon.functionParameterEnd &&
        curTok.type != Semantic.endOfFile) {
      // it's possible that it's an empty arguments list, so we manually handle precedings here
      handlePrecedings();
      if (curTok.type == lexicon.functionParameterEnd) break;
      hasAnyArgs = true;
      if (expect([Semantic.identifier, lexicon.namedArgumentValueIndicator],
          consume: false)) {
        final name = match(Semantic.identifier).lexeme;
        match(lexicon.namedArgumentValueIndicator);
        final namedArg = parseExpr();
        handleTrailing(namedArg,
            endMarkForCommaExpressions: lexicon.functionParameterEnd);
        namedArgs[name] = namedArg;
      } else {
        ASTNode positionalArg;
        if (curTok.type == lexicon.spreadSyntax) {
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
            endMarkForCommaExpressions: lexicon.functionParameterEnd);
        positionalArgs.add(positionalArg);
      }
    }
    final endTok = match(lexicon.functionParameterEnd);
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
  /// Assignment operator =, precedence 1, associativity right
  @override
  ASTNode parseExpr() {
    ASTNode? expr;
    final left = _parserTernaryExpr();
    if (lexicon.assignments.contains(curTok.type)) {
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
    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  ASTNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([lexicon.ternaryThen], consume: true)) {
      _isLegalLeftValue = false;
      final thenBranch = _parserTernaryExpr();
      match(lexicon.ternaryElse);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: currentSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// If null: e1 ?? e2, precedence 4, associativity left
  ASTNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.type == lexicon.ifNull) {
      _isLegalLeftValue = false;
      while (curTok.type == lexicon.ifNull) {
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

  /// Logical or: ||, precedence 5, associativity left
  ASTNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == lexicon.logicalOr) {
      _isLegalLeftValue = false;
      while (curTok.type == lexicon.logicalOr) {
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

  /// Logical and: &&, precedence 6, associativity left
  ASTNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == lexicon.logicalAnd) {
      _isLegalLeftValue = false;
      while (curTok.type == lexicon.logicalAnd) {
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

  /// Logical equal: ==, !=, precedence 7, associativity none
  ASTNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (lexicon.equalitys.contains(curTok.type)) {
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

  /// Logical compare: <, >, <=, >=, as, is, is!, in, in!, precedence 8, associativity none
  ASTNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (lexicon.logicalRelationals.contains(curTok.type)) {
      _isLegalLeftValue = false;
      final op = advance();
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexicon.setRelationals.contains(curTok.type)) {
      _isLegalLeftValue = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIn) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kNotIn
            : lexicon.kIn;
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
    } else if (lexicon.typeRelationals.contains(curTok.type)) {
      _isLegalLeftValue = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIs) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kIsNot
            : lexicon.kIs;
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

  /// Add: +, -, precedence 13, associativity left
  ASTNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (lexicon.additives.contains(curTok.type)) {
      _isLegalLeftValue = false;
      while (lexicon.additives.contains(curTok.type)) {
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

  /// Multiply *, /, ~/, %, precedence 14, associativity left
  ASTNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (lexicon.multiplicatives.contains(curTok.type)) {
      _isLegalLeftValue = false;
      while (lexicon.multiplicatives.contains(curTok.type)) {
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

  /// Prefix -e, !e，++e, --e, await e, precedence 15, associativity none
  ASTNode _parseUnaryPrefixExpr() {
    if (!(lexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance();
      // if (op.type == lexicon.kAwait) {
      // TODO: check if await is allowed
      // }
      final value = _parseUnaryPostfixExpr();
      if (lexicon.unaryPrefixsThatChangeTheValue.contains(op.type)) {
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
      return UnaryPrefixExpr(op.lexeme, value,
          source: currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// Postfix e., e?., e[], e?[], e(), e?(), e++, e-- precedence 16, associativity right
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (lexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance();
      if (op.type == lexicon.memberGet) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        _isLegalLeftValue = true;
        final name = match(Semantic.identifier);
        final key = IdentifierExpr(name.lexeme,
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
      } else if (op.type == lexicon.nullableMemberGet) {
        _isLegalLeftValue = false;
        final name = match(Semantic.identifier);
        final key = IdentifierExpr(name.lexeme,
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
      } else if (op.type == lexicon.subGetStart) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        var indexExpr = parseExpr();
        _isLegalLeftValue = true;
        match(lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.nullableSubGet) {
        var indexExpr = parseExpr();
        _isLegalLeftValue = true;
        match(lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.nullableFunctionArgumentCall) {
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
      } else if (op.type == lexicon.functionParameterStart) {
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
      } else if (op.type == lexicon.postIncrement ||
          op.type == lexicon.postDecrement) {
        _isLegalLeftValue = false;
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

    // We cannot use 'switch case' here because we have to use lexicon's value, which is not constant.
    if (curTok.type == lexicon.kNull) {
      final token = advance();
      _isLegalLeftValue = false;
      expr = ASTLiteralNull(
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (expr == null && curTok.type == Semantic.literalBoolean) {
      final token = match(Semantic.literalBoolean) as TokenBooleanLiteral;
      _isLegalLeftValue = false;
      expr = ASTLiteralBoolean(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (expr == null && curTok.type == Semantic.literalInteger) {
      final token = match(Semantic.literalInteger) as TokenIntLiteral;
      _isLegalLeftValue = false;
      expr = ASTLiteralInteger(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (expr == null && curTok.type == Semantic.literalFloat) {
      final token = advance() as TokenFloatLiteral;
      _isLegalLeftValue = false;
      expr = ASTLiteralFloat(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (expr == null && curTok.type == Semantic.literalString) {
      final token = advance() as TokenStringLiteral;
      _isLegalLeftValue = false;
      expr = ASTLiteralString(token.literal, token.startMark, token.endMark,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (expr == null && curTok.type == Semantic.literalStringInterpolation) {
      final token = advance() as TokenStringInterpolation;
      final interpolations = <ASTNode>[];
      final savedCurrent = curTok;
      final savedFirst = firstTok;
      final savedEnd = endOfFile;
      final savedLine = line;
      final savedColumn = column;
      for (final token in token.interpolations) {
        final nodes = parseTokens(token,
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
          RegExp(lexicon.stringInterpolationPattern),
          (Match m) =>
              '${lexicon.stringInterpolationStart}${i++}${lexicon.stringInterpolationEnd}');
      _isLegalLeftValue = false;
      expr = ASTStringInterpolation(
          text, token.startMark, token.endMark, interpolations,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    // this expression
    if (expr == null && curTok.type == lexicon.kThis) {
      if (_currentFunctionCategory == null ||
          (_currentFunctionCategory != FunctionCategory.literal &&
              (_currentClassDeclaration == null && _currentStructId == null))) {
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
    }

    // super constructor call
    if (curTok.type == lexicon.kSuper) {
      if (_currentClassDeclaration == null ||
          _currentFunctionCategory == null ||
          _currentClassDeclaration?.superType == null) {
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
    }

    // constructor call
    if (expr == null && curTok.type == lexicon.kNew) {
      final keyword = advance();
      _isLegalLeftValue = false;
      final idTok = match(Semantic.identifier) as TokenIdentifier;
      final id = IdentifierExpr.fromToken(idTok,
          isMarked: idTok.isMarked, source: currentSource);
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      ASTEmptyLine? empty;
      if (expect([lexicon.functionParameterStart], consume: true)) {
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
    }

    // an if expression
    if (expr == null && curTok.type == lexicon.kIf) {
      _isLegalLeftValue = false;
      expr = _parseIf(isStatement: false);
    }

    // when expression
    if (expr == null && curTok.type == lexicon.kWhen) {
      _isLegalLeftValue = false;
      expr = _parseWhen(isStatement: false);
    }

    // literal function expression
    if (expr == null && curTok.type == lexicon.functionParameterStart) {
      final tokenAfterGroupExprStart = curTok.next;
      final tokenAfterGroupExprEnd = seekGroupClosing(
          {lexicon.functionParameterStart: lexicon.functionParameterEnd});
      if ((tokenAfterGroupExprStart?.type == lexicon.groupExprEnd ||
              (tokenAfterGroupExprStart?.type == Semantic.identifier &&
                  (tokenAfterGroupExprStart?.next?.type == lexicon.comma ||
                      tokenAfterGroupExprStart?.next?.type ==
                          lexicon.typeIndicator ||
                      tokenAfterGroupExprStart?.next?.type ==
                          lexicon.groupExprEnd))) &&
          (tokenAfterGroupExprEnd.type == lexicon.codeBlockStart ||
              tokenAfterGroupExprEnd.type ==
                  lexicon.functionSingleLineBodyIndicator ||
              tokenAfterGroupExprEnd.type == lexicon.kAsync)) {
        _isLegalLeftValue = false;
        expr = _parseFunction(
            category: FunctionCategory.literal, hasKeyword: false);
      }
    }

    if (expr == null && curTok.type == lexicon.groupExprStart) {
      final start = advance();
      final innerExpr = parseExpr();
      final end = match(lexicon.groupExprEnd);
      _isLegalLeftValue = false;
      expr = GroupExpr(innerExpr,
          source: currentSource,
          line: start.line,
          column: start.column,
          offset: start.offset,
          length: end.offset + end.length - start.offset);
    }

    // literal list value
    if (expr == null && curTok.type == lexicon.listStart) {
      final start = advance();
      final listExprs = parseExprList(
        endToken: lexicon.listEnd,
        parseFunction: () {
          if (curTok.type == lexicon.listEnd) return null;
          ASTNode item;
          if (curTok.type == lexicon.spreadSyntax) {
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
      final endTok = match(lexicon.listEnd);
      _isLegalLeftValue = false;
      expr = ListExpr(listExprs,
          source: currentSource,
          line: start.line,
          column: start.column,
          offset: start.offset,
          length: endTok.end - start.offset);
    }

    if (expr == null && curTok.type == lexicon.codeBlockStart) {
      _isLegalLeftValue = false;
      expr = _parseStructObj();
    }

    if (expr == null && curTok.type == lexicon.kStruct) {
      _isLegalLeftValue = false;
      expr = _parseStructObj(hasKeyword: true);
    }

    if (expr == null && curTok.type == lexicon.kFun) {
      _isLegalLeftValue = false;
      expr = _parseFunction(category: FunctionCategory.literal);
    }

    // if (expr == null && curTok.type == lexicon.kAsync) {
    //   _isLegalLeftValue = false;
    //   expr = _parseFunction(category: FunctionCategory.literal, isAsync: true);
    // }

    if (expr == null && curTok.type == Semantic.identifier) {
      final id = advance() as TokenIdentifier;
      final isLocal = curTok.type != lexicon.assign;
      // TODO: type arguments
      _isLegalLeftValue = true;
      expr = IdentifierExpr.fromToken(id,
          isMarked: id.isMarked, isLocal: isLocal, source: currentSource);
    }

    if (expr == null) {
      final err = HTError.unexpected(
          Semantic.expression, Semantic.expression, curTok.lexeme,
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
    return InOfExpr(collection, opTok.lexeme == lexicon.kOf ? true : false,
        line: collection.line,
        column: collection.column,
        offset: collection.offset,
        length: curTok.offset - collection.offset);
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == lexicon.groupExprStart) {
      final savedPrecedings = savePrecedings();
      final startTok = advance();
      // TODO: generic parameters
      var isOptional = false;
      var isNamed = false;
      final parameters = <ParamTypeExpr>[];
      // function parameters are a bit complex so we didn't use [parseExprList] here.
      while (curTok.type != lexicon.functionParameterEnd &&
          curTok.type != Semantic.endOfFile) {
        handlePrecedings();
        if (curTok.type == lexicon.functionParameterEnd) {
          // TODO: store comments within empty function parameter list
          break;
        }
        // optional positional args
        if (!isOptional &&
            !isNamed &&
            expect([lexicon.optionalPositionalParameterStart], consume: true)) {
          isOptional = true;
          bool alreadyHasVariadic = false;
          final optionalPositionalParameters = parseExprList(
            endToken: lexicon.optionalPositionalParameterEnd,
            parseFunction: () {
              final isVariadic = expect([lexicon.variadicArgs], consume: true);
              if (alreadyHasVariadic && isVariadic) {
                final err = HTError.unexpected(Semantic.funcTypeExpr,
                    Semantic.paramTypeExpr, lexicon.variadicArgs,
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
          match(lexicon.optionalPositionalParameterEnd);
          parameters.addAll(optionalPositionalParameters);
        }
        // optional named args
        else if (!isOptional &&
            !isNamed &&
            expect([lexicon.namedParameterStart], consume: true)) {
          isNamed = true;
          final namedParameters = parseExprList(
            endToken: lexicon.optionalPositionalParameterEnd,
            parseFunction: () {
              final paramId = match(Semantic.identifier);
              final paramSymbol =
                  IdentifierExpr.fromToken(paramId, source: currentSource);
              match(lexicon.typeIndicator);
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
          match(lexicon.namedParameterStart);
          parameters.addAll(namedParameters);
        }
        // mandatory positional args
        else {
          bool isVariadic = expect([lexicon.variadicArgs], consume: true);
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
              endMarkForCommaExpressions: lexicon.functionParameterEnd);
        }
      }
      match(lexicon.functionParameterEnd);
      match(lexicon.functionReturnTypeIndicator);
      final returnType = _parseTypeExpr();
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
    else if (curTok.type == lexicon.structStart) {
      final savedPrecedings = savePrecedings();
      final startTok = advance();
      final fieldTypes = parseExprList(
        endToken: lexicon.codeBlockEnd,
        parseFunction: () {
          if (curTok.type == Semantic.literalString ||
              curTok.type == Semantic.identifier) {
            final savedPrecedings = savePrecedings();
            final idTok = advance();
            match(lexicon.typeIndicator);
            final typeExpr = _parseTypeExpr();
            final expr = FieldTypeExpr(idTok.literal, typeExpr);
            currentPrecedings = savedPrecedings;
            setPrecedings(expr);
            return expr;
          } else {
            return null;
          }
        },
      );
      match(lexicon.codeBlockEnd);
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
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: currentSource);
      if (id.id == lexicon.typeAny) {
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
      } else if (id.id == lexicon.typeUnknown) {
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
      } else if (id.id == lexicon.typeVoid) {
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
      } else if (id.id == lexicon.typeNever) {
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
      } else if (id.id == lexicon.typeFunction) {
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
      } else if (id.id == lexicon.typeNamespace) {
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
        List<TypeExpr> typeArgs = [];
        if (expect([lexicon.typeListStart], consume: true)) {
          typeArgs = parseExprList(
            endToken: lexicon.typeListEnd,
            parseFunction: () => _parseTypeExpr(),
          );
          match(lexicon.typeListEnd);
          if (typeArgs.isEmpty) {
            final err = HTError.unexpectedEmptyList(Semantic.typeArguments,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.end - idTok.offset);
            errors.add(err);
          }
        }
        final isNullable = expect([lexicon.nullableTypePostfix], consume: true);
        final nominalType = NominalTypeExpr(
          id: id,
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
    bool isCodeBlock = true,
    bool isLoop = false,
  }) {
    final startTok = match(lexicon.codeBlockStart);
    final savedPrecedings = savePrecedings();
    final savedIsLoopFlag = _isInLoop;
    if (isLoop) _isInLoop = true;
    final statements = parseExprList(
      endToken: lexicon.codeBlockEnd,
      parseFunction: () => parseStmt(style: sourceType),
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
    final endTok = match(lexicon.codeBlockEnd);
    final block = BlockStmt(statements,
        id: id,
        isCodeBlock: isCodeBlock,
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
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
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
    if (curTok.type != lexicon.codeBlockEnd &&
        curTok.type != lexicon.endOfStatementMark) {
      expr = parseExpr();
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    return ReturnStmt(keyword,
        returnValue: expr,
        source: currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseExprOrStmtOrBlock({bool isStatement = true}) {
    if (curTok.type == lexicon.codeBlockStart) {
      return _parseBlockStmt(id: Semantic.elseBranch);
    } else {
      if (isStatement) {
        final startTok = curTok;
        var node = parseStmt(style: ParseStyle.functionDefinition);
        if (node == null) {
          final err = HTError.unexpected(
              Semantic.exprStmt, Semantic.expression, curTok.lexeme,
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
        return parseExpr();
      }
    }
  }

  IfStmt _parseIf({bool isStatement = true}) {
    final keyword = match(lexicon.kIf);
    match(lexicon.groupExprStart);
    final condition = parseExpr();
    match(lexicon.groupExprEnd);
    var thenBranch = _parseExprOrStmtOrBlock(isStatement: isStatement);
    handlePrecedings();
    ASTNode? elseBranch;
    if (isStatement) {
      if (expect([lexicon.kElse], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isStatement: isStatement);
      }
    } else {
      match(lexicon.kElse);
      elseBranch = _parseExprOrStmtOrBlock(isStatement: isStatement);
    }
    return IfStmt(condition, thenBranch,
        isStatement: isStatement,
        elseBranch: elseBranch,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(lexicon.kWhile);
    match(lexicon.groupExprStart);
    final condition = parseExpr();
    match(lexicon.groupExprEnd);
    final loop = _parseBlockStmt(id: Semantic.whileLoop, isLoop: true);
    return WhileStmt(condition, loop,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance();
    final loop = _parseBlockStmt(id: Semantic.doLoop, isLoop: true);
    ASTNode? condition;
    if (expect([lexicon.kWhile], consume: true)) {
      match(lexicon.groupExprStart);
      condition = parseExpr();
      match(lexicon.groupExprEnd);
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
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
    final hasBracket = expect([lexicon.groupExprStart], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    ASTNode? condition;
    ASTNode? increment;
    if (forStmtType == lexicon.kIn || forStmtType == lexicon.kOf) {
      if (!lexicon.forDeclarationKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            Semantic.forStmt, Semantic.variableDeclaration, curTok.type,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != lexicon.VAR,
          isMutable: curTok.type != lexicon.kFinal);
      advance();
      final collection = parseExpr();
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop, isLoop: true);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == lexicon.kOf,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != lexicon.VAR,
            isMutable: curTok.type != lexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(lexicon.endOfStatementMark);
      }
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        condition = parseExpr();
      }
      match(lexicon.endOfStatementMark);
      if (!expect([lexicon.groupExprEnd], consume: false)) {
        increment = parseExpr();
      }
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop, isLoop: true);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhen({bool isStatement = true}) {
    final keyword = advance();
    ASTNode? condition;
    if (curTok.type != lexicon.codeBlockStart) {
      match(lexicon.groupExprStart);
      condition = parseExpr();
      match(lexicon.groupExprEnd);
    }
    final options = <ASTNode, ASTNode>{};
    ASTNode? elseBranch;
    match(lexicon.codeBlockStart);
    // when branches are a bit complex so we didn't use [parseExprList] here.
    while (curTok.type != lexicon.codeBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      handlePrecedings();
      if (curTok.type == lexicon.codeBlockEnd && options.isNotEmpty) break;
      if (curTok.lexeme == lexicon.kElse) {
        advance();
        match(lexicon.whenBranchIndicator);
        elseBranch = _parseExprOrStmtOrBlock(isStatement: isStatement);
      } else {
        ASTNode caseExpr;
        if (peek(1).type == lexicon.comma) {
          caseExpr =
              _handleCommaExpr(lexicon.whenBranchIndicator, isLocal: false);
        } else if (curTok.type == lexicon.kIn) {
          caseExpr = _handleInOfExpr();
        } else {
          caseExpr = parseExpr();
        }
        match(lexicon.whenBranchIndicator);
        var caseBranch = _parseExprOrStmtOrBlock(isStatement: isStatement);
        options[caseExpr] = caseBranch;
      }
    }
    match(lexicon.codeBlockEnd);
    assert(options.isNotEmpty);
    if (currentPrecedings.isNotEmpty) {
      options.values.last.succeedings = currentPrecedings;
      currentPrecedings = [];
    }
    return WhenStmt(options, elseBranch, condition,
        isStatement: isStatement,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    List<GenericTypeParameterExpr> genericParams = [];
    if (expect([lexicon.typeListStart], consume: true)) {
      genericParams = parseExprList(
        endToken: lexicon.typeListEnd,
        parseFunction: () {
          final idTok = match(Semantic.identifier);
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
      match(lexicon.typeListEnd);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    final keyword = advance(); // not a keyword so don't use match
    List<IdentifierExpr> showList = [];
    if (curTok.type == lexicon.importExportListStart) {
      advance();
      showList = parseExprList(
        endToken: lexicon.importExportListEnd,
        parseFunction: () {
          final idTok = match(Semantic.identifier);
          final id = IdentifierExpr.fromToken(idTok, source: currentSource);
          setPrecedings(id);
          return id;
        },
      );
      match(lexicon.codeBlockEnd);
      if (showList.isEmpty) {
        final err = HTError.unexpectedEmptyList(Semantic.importSymbols,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors.add(err);
      }

      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance().lexeme;
      if (fromKeyword != lexicon.kFrom) {
        final err = HTError.unexpected(
            Semantic.importStmt, lexicon.kFrom, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
    }
    IdentifierExpr? alias;
    late bool hasEndOfStmtMark;

    void _handleAlias() {
      match(lexicon.kAs);
      final aliasId = match(Semantic.identifier);
      alias = IdentifierExpr.fromToken(aliasId, source: currentSource);
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    }

    final fromPathTok = match(Semantic.literalString);
    String fromPathRaw = fromPathTok.literal;
    String fromPath;
    bool isPreloadedModule = false;
    if (fromPathRaw.startsWith(HTResourceContext.hetuPreloadedModulesPrefix)) {
      isPreloadedModule = true;
      fromPath = fromPathRaw
          .substring(HTResourceContext.hetuPreloadedModulesPrefix.length);
      _handleAlias();
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
        _handleAlias();
      } else {
        if (curTok.type == lexicon.kAs) {
          _handleAlias();
        } else {
          hasEndOfStmtMark =
              expect([lexicon.endOfStatementMark], consume: true);
        }
      }
    }

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
    if (expect([lexicon.codeBlockStart], consume: true)) {
      final showList = parseExprList(
        endToken: lexicon.importExportListEnd,
        parseFunction: () {
          final idTok = match(Semantic.identifier);
          final id = IdentifierExpr.fromToken(idTok, source: currentSource);
          setPrecedings(id);
          return id;
        },
      );
      match(lexicon.codeBlockEnd);
      String? fromPath;
      var hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == lexicon.kFrom) {
        advance();
        final fromPathTok = match(Semantic.literalString);
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
        hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
      }
      stmt = ImportExportDecl(
          fromPath: fromPath,
          showList: showList,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        currentModuleImports.add(stmt);
      }
    } else if (expect([lexicon.everythingMark], consume: true)) {
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      stmt = ImportExportDecl(
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final key = match(Semantic.literalString);
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      stmt = ImportExportDecl(
          fromPath: key.literal,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      currentModuleImports.add(stmt);
    }
    return stmt;
  }

  ASTNode _parseDeleteStmt() {
    var keyword = advance();
    final nextTok = peek(1);
    if (curTok.type == Semantic.identifier &&
        nextTok.type != lexicon.memberGet &&
        nextTok.type != lexicon.subGetStart) {
      final id = advance().lexeme;
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      return DeleteStmt(id,
          source: currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = parseExpr();
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
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
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    // final savedSurrentExplicitNamespaceId = _currentExplicitNamespaceId;
    // _currentExplicitNamespaceId = idTok.lexeme;
    final definition = _parseBlockStmt(
        id: id.id, sourceType: ParseStyle.namespace, isCodeBlock: false);
    // _currentExplicitNamespaceId = savedSurrentExplicitNamespaceId;
    return NamespaceDecl(
      id,
      definition,
      classId: _currentClassDeclaration?.id,
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
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    final genericParameters = _getGenericParams();
    match(lexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(id, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isTopLevel: isTopLevel,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateFinalize = false,
      bool lateInitialize = false,
      ASTNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
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
    if (expect([lexicon.typeIndicator], consume: true)) {
      declType = _parseTypeExpr();
    }
    ASTNode? initializer;
    if (!lateFinalize) {
      if (isConst) {
        match(lexicon.assign);
        initializer = parseExpr();
      } else {
        if (expect([lexicon.assign], consume: true)) {
          initializer = parseExpr();
        } else {
          initializer = additionalInitializer;
        }
      }
    }
    bool hasEndOfStmtMark = hasEndOfStatement;
    if (hasEndOfStatement) {
      match(lexicon.endOfStatementMark);
    } else {
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    }
    return VarDecl(id,
        internalName: internalName,
        classId: classId,
        declType: declType,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isField: isField,
        isExternal: isExternal,
        isStatic: isConst && classId != null ? true : isStatic,
        isConst: isConst,
        isMutable: !isConst && isMutable,
        isTopLevel: isTopLevel,
        lateFinalize: lateFinalize,
        lateInitialize: lateInitialize,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DestructuringDecl _parseDestructuringDecl(
      {bool isTopLevel = false, bool isMutable = false}) {
    final keyword = advance(2);
    final ids = <IdentifierExpr, TypeExpr?>{};
    bool isVector = false;
    String endMark;
    if (peek(-1).type == lexicon.listStart) {
      endMark = lexicon.listEnd;
      isVector = true;
    } else {
      endMark = lexicon.codeBlockEnd;
    }
    // declarations are a bit complex so we didn't use [parseExprList] here.
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      handlePrecedings();
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: currentSource);
      setPrecedings(id);
      TypeExpr? declType;
      if (expect([lexicon.typeIndicator], consume: true)) {
        declType = _parseTypeExpr();
      }
      ids[id] = declType;
      handleTrailing(declType ?? id, endMarkForCommaExpressions: endMark);
    }
    match(endMark);
    match(lexicon.assign);
    final initializer = parseExpr();
    bool hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
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
        length: curTok.offset - keyword.offset);
  }

  FuncDecl _parseFunction(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool hasKeyword = true,
      // bool isAsync = false,
      bool isField = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false}) {
    final savedCurrentFunctionCategory = _currentFunctionCategory;
    _currentFunctionCategory = category;
    late Token startTok;
    String? externalTypedef;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance();
      if (!isExternal &&
          (isStatic ||
              category == FunctionCategory.normal ||
              category == FunctionCategory.literal)) {
        if (expect([lexicon.listStart], consume: true)) {
          externalTypedef = match(Semantic.identifier).lexeme;
          match(lexicon.listEnd);
        }
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.factoryConstructor:
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? InternalIdentifier.defaultConstructor
            : '${InternalIdentifier.namedConstructorPrefix}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? '${InternalIdentifier.anonymousFunction}${HTParser.anonymousFunctionIndex++}'
            : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.setter}$id';
        break;
      default:
        id = match(Semantic.identifier);
        internalName = id.lexeme;
    }
    final genericParameters = _getGenericParams();
    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    List<ParamDecl> paramDecls = [];
    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([lexicon.functionParameterStart], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      bool allowVariadic = true;

      ParamDecl parseParam() {
        bool isParamVariadic = false;
        if (allowVariadic) {
          isParamVariadic = expect([lexicon.variadicArgs], consume: true);
          if (isFuncVariadic && isParamVariadic) {
            final err = HTError.unexpected(Semantic.funcTypeExpr,
                Semantic.paramTypeExpr, lexicon.variadicArgs,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
          }
          isFuncVariadic = isParamVariadic;
        }
        TypeExpr? paramDeclType;
        IdentifierExpr paramSymbol;
        bool hasThisInitializingSyntax = false;
        if (category == FunctionCategory.constructor) {
          hasThisInitializingSyntax = expect([lexicon.kThis], consume: true);
        }
        if (hasThisInitializingSyntax) {
          hasThisInitializingSyntax = true;
          match(lexicon.memberGet);
        }
        final paramId = match(Semantic.identifier);
        paramSymbol = IdentifierExpr.fromToken(paramId, source: currentSource);

        if (!hasThisInitializingSyntax) {
          if (expect([lexicon.typeIndicator], consume: true)) {
            paramDeclType = _parseTypeExpr();
          }
        }

        ASTNode? initializer;
        if (expect([lexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = parseExpr();
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

      while (curTok.type != lexicon.functionParameterEnd &&
          curTok.type != Semantic.endOfFile) {
        handlePrecedings();
        if (curTok.type == lexicon.functionParameterEnd) {
          // TODO: store comments within empty function parameter list
          break;
        }
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional &&
            !isNamed &&
            expect([lexicon.optionalPositionalParameterStart], consume: true)) {
          isOptional = true;
          final params = parseExprList(
            endToken: lexicon.optionalPositionalParameterEnd,
            parseFunction: parseParam,
          );
          maxArity += params.length;
          match(lexicon.optionalPositionalParameterEnd);
          paramDecls.addAll(params);
        }
        //检查命名参数, 根据是否有花括号判断
        else if (!isOptional &&
            !isNamed &&
            expect([lexicon.namedParameterStart], consume: true)) {
          isNamed = true;
          allowVariadic = false;
          final params = parseExprList(
            endToken: lexicon.namedParameterEnd,
            parseFunction: parseParam,
          );
          match(lexicon.namedParameterEnd);
          paramDecls.addAll(params);
        } else {
          ++minArity;
          ++maxArity;
          final param = parseParam();
          paramDecls.add(param);
          handleTrailing(param,
              endMarkForCommaExpressions: lexicon.functionParameterEnd);
        }
      }
      final endTok = match(lexicon.functionParameterEnd);
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
    RedirectingConstructorCallExpr? referCtor;
    // the return value type declaration
    if (expect([lexicon.functionReturnTypeIndicator], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            Semantic.function, Semantic.functionDefinition, Semantic.returnType,
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
    else if (expect([lexicon.constructorInitializationListIndicator],
        consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.unexpected(
            Semantic.function,
            lexicon.codeBlockStart,
            lexicon.constructorInitializationListIndicator,
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
      if (!lexicon.redirectingConstructorCallKeywords
          .contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(
            Semantic.function, Semantic.ctorCallExpr, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors.add(err);
      }
      Token? ctorKey;
      if (expect([lexicon.memberGet], consume: true)) {
        ctorKey = match(Semantic.identifier);
        match(lexicon.groupExprStart);
      } else {
        match(lexicon.groupExprStart);
      }
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
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
    bool isAsync = false;
    if (category == FunctionCategory.normal ||
        category == FunctionCategory.method ||
        category == FunctionCategory.literal) {
      if (expect([lexicon.kAsync], consume: true)) {
        isAsync = true;
      }
    }
    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    ASTNode? definition;
    if (curTok.type == lexicon.codeBlockStart) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: Semantic.functionCall);
    } else if (expect([lexicon.functionSingleLineBodyIndicator],
        consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = parseExpr();
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    } else if (expect([lexicon.assign], consume: true)) {
      final err = HTError.unsupported(Semantic.redirectingFunctionDefinition,
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
      if (category != FunctionCategory.literal) {
        expect([lexicon.endOfStatementMark], consume: true);
      }
    }
    _currentFunctionCategory = savedCurrentFunctionCategory;
    final funcDecl = FuncDecl(internalName,
        id: id != null
            ? IdentifierExpr.fromToken(id, source: currentSource)
            : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        returnType: returnType,
        minArity: minArity,
        maxArity: maxArity,
        isExpressionBody: isExpressionBody,
        hasEndOfStmtMark: hasEndOfStmtMark,
        definition: definition,
        isAsync: isAsync,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isTopLevel: isTopLevel,
        category: category,
        source: currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
    return funcDecl;
  }

  ClassDecl _parseClassDecl(
      {String? classId,
      bool isExternal = false,
      bool isAbstract = false,
      bool isTopLevel = false,
      bool lateResolve = true}) {
    final keyword = match(lexicon.kClass);
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
    final id = match(Semantic.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (curTok.lexeme == lexicon.kExtends) {
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
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: ParseStyle.classDefinition,
        isCodeBlock: false,
        id: Semantic.classDefinition);
    final classDecl = ClassDecl(
        IdentifierExpr.fromToken(id, source: currentSource), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        lateResolve: lateResolve,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _currentClassDeclaration = savedClass;

    return classDecl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(lexicon.kEnum);
    final id = match(Semantic.identifier);
    var enumerations = <IdentifierExpr>[];
    bool isPreviousItemEndedWithComma = false;
    if (expect([lexicon.codeBlockStart], consume: true)) {
      while (curTok.type != lexicon.codeBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        final hasPrecedingComments = handlePrecedings();
        if (hasPrecedingComments &&
            !isPreviousItemEndedWithComma &&
            enumerations.isNotEmpty) {
          enumerations.last.succeedings.addAll(currentPrecedings);
          break;
        }
        if ((curTok.type == lexicon.codeBlockEnd) ||
            (curTok.type == Semantic.endOfFile)) {
          break;
        }
        isPreviousItemEndedWithComma = false;
        final enumIdTok = match(Semantic.identifier);
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: currentSource);
        setPrecedings(enumId);
        handleTrailing(enumId,
            endMarkForCommaExpressions: lexicon.codeBlockEnd);
        enumerations.add(enumId);
      }
      match(lexicon.codeBlockEnd);
    } else {
      expect([lexicon.endOfStatementMark], consume: true);
    }
    final enumDecl = EnumDecl(
        IdentifierExpr.fromToken(id, source: currentSource), enumerations,
        isExternal: isExternal,
        isTopLevel: isTopLevel,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);

    return enumDecl;
  }

  StructDecl _parseStructDecl({bool isTopLevel = false}) {
    //, bool lateInitialize = true}) {
    final keyword = match(lexicon.kStruct);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    IdentifierExpr? prototypeId;
    List<IdentifierExpr> mixinIds = [];
    if (expect([lexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(Semantic.identifier);
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
    } else if (expect([lexicon.kWith], consume: true)) {
      while (curTok.type != lexicon.codeBlockStart &&
          curTok.type != Semantic.endOfFile) {
        final mixinIdTok = match(Semantic.identifier);
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
            endMarkForCommaExpressions: lexicon.codeBlockStart);
        mixinIds.add(mixinId);
      }
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <ASTNode>[];
    final startTok = match(lexicon.codeBlockStart);
    while (curTok.type != lexicon.codeBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      handlePrecedings();
      if (curTok.type == lexicon.codeBlockEnd) break;
      final stmt = parseStmt(style: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(lexicon.codeBlockEnd);
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
    final structDecl = StructDecl(id, definition,
        prototypeId: prototypeId,
        mixinIds: mixinIds,
        isTopLevel: isTopLevel,
        // lateInitialize: lateInitialize,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    return structDecl;
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(lexicon.kStruct);
      if (hasKeyword && expect([lexicon.kExtends], consume: true)) {
        final idTok = match(Semantic.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok, source: currentSource);
      }
    }
    prototypeId ??= IdentifierExpr(lexicon.globalPrototypeId);
    final structBlockStartTok = match(lexicon.structStart);
    final fields = <StructObjField>[];
    // struct are a bit complex so we didn't use [parseExprList] here.
    while (
        curTok.type != lexicon.structEnd && curTok.type != Semantic.endOfFile) {
      handlePrecedings();
      if (curTok.type == lexicon.structEnd) {
        break;
      }
      if (curTok.type == Semantic.identifier ||
          curTok.type == Semantic.literalString) {
        final keyTok = advance();
        StructObjField field;
        if (curTok.type == lexicon.comma || curTok.type == lexicon.structEnd) {
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
          match(lexicon.structValueIndicator);
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
        handleTrailing(field, endMarkForCommaExpressions: lexicon.structEnd);
      } else if (curTok.type == lexicon.spreadSyntax) {
        advance();
        final value = parseExpr();
        final field = StructObjField(fieldValue: value);
        fields.add(field);
        fields.add(field);
        handleTrailing(field, endMarkForCommaExpressions: lexicon.structEnd);
      } else {
        final errTok = advance();
        final err = HTError.structMemberId(curTok.type,
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
    match(lexicon.structEnd);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
