import 'dart:io';

import 'package:path/path.dart' as path;

import 'errors.dart';
import 'object.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';
import 'interpreter.dart';
import 'internal_functions.dart';

abstract class Hetu {
  static var _init = false;
  static bool get isInit => _init;

  static void init(
      {Interpreter interpreter, String preloadDir, String language, Map<String, HetuFunctionCall> bindMap}) {
    try {
      if (interpreter != null) {
        interpreter.bindAll(HetuBuildInFunction.bindmap);
        interpreter.bindAll(bindMap);
      }

      if (!isInit) {
        globalInterpreter.bindAll(HetuBuildInFunction.bindmap);
        globalInterpreter.bindAll(bindMap);

        if (preloadDir != null) {
          print('Hetu: Preload directory set to [$preloadDir].');
          var dirObj = Directory(preloadDir);
          var list = dirObj.listSync();
          for (var file in list) {
            if (file is File) {
              print('Hetu: loading script file [${path.basename(file.path)}]...');
              eval(file.readAsStringSync());
            }
          }
        }

        _init = true;
      }
    } catch (e) {
      print(e);
      print('Hetu init failed!');
    }
  }

  static void bind(String name, HetuFunctionCall function) => globalInterpreter.bind(name, function);

  static void invoke(String name, {Interpreter interpreter, List<dynamic> args}) {
    HetuError.clear();
    var itp = interpreter ?? globalInterpreter;
    try {
      itp.invoke(name, args: args);
    } catch (e) {
      print(e);
    } finally {
      HetuError.output();
    }
  }

  static void eval(String script,
      {Interpreter interpreter,
      ParserContext context = ParserContext.program,
      String invokeFunc = null,
      List<dynamic> args}) {
    var itp = interpreter ?? globalInterpreter;

    HetuError.clear();
    try {
      var commandLine = ((context == ParserContext.commandLine) || (context == ParserContext.commandLineScript));
      final _lexer = Lexer();
      final _parser = Parser();
      final _resolver = Resolver();
      var tokens = _lexer.lex(script, commandLine: commandLine);
      var statements = _parser.parse(tokens, context: context);
      var locals = _resolver.resolve(statements);
      itp.interpreter(
        statements,
        locals,
        commandLine: commandLine,
        invokeFunc: invokeFunc,
        args: args,
      );
    } catch (e) {
      print(e);
    } finally {
      HetuError.output();
    }
  }

  /// 解析文件
  static void evalf(String path,
          {Interpreter interpreter,
          ParserContext context = ParserContext.program,
          String invokeFunc = null,
          List<dynamic> args}) =>
      eval(File(path).readAsStringSync(),
          interpreter: interpreter, context: context, invokeFunc: invokeFunc, args: args);

  /// 解析多个文件
  static void evalfs(Set<String> paths,
      {Interpreter interpreter,
      ParserContext context = ParserContext.program,
      String invokeFunc = null,
      List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      chunk += File(file).readAsStringSync();
    }
    eval(chunk, interpreter: interpreter, context: context, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  static void evalfs2(List<FileSystemEntity> paths,
      {Interpreter interpreter,
      ParserContext context = ParserContext.program,
      String invokeFunc = null,
      List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      if (file is File) chunk += file.readAsStringSync();
    }
    eval(chunk, interpreter: interpreter, context: context, invokeFunc: invokeFunc, args: args);
  }

  /// 解析命令行
  static void evalc(String commandLine, {List<dynamic> args}) =>
      eval(commandLine, args: args, context: ParserContext.commandLine);
}
