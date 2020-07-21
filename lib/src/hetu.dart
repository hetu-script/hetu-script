import 'dart:io';

import 'package:path/path.dart' as path;

import 'errors.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';
import 'interpreter.dart';
import 'internal_functions.dart';
import 'function.dart';
import 'common.dart';
import 'class.dart';

abstract class Hetu {
  static var _init = false;
  static bool get isInit => _init;

  static void loadDir(String path, {Context context}) {}

  static void init({
    Context context,
    String preloadDir,
    String language,
    Map<String, Call> bindMap,
    Map<String, Call> linkMap,
  }) {
    try {
      Directory dirObj;
      List<FileSystemEntity> fileList;

      if (!isInit) {
        print('Hetu: Core library path set to [${HS_Common.coreLibPath}].');
        dirObj = Directory(HS_Common.coreLibPath);
        fileList = dirObj.listSync();
        for (var file in fileList) {
          if (file is File) {
            print('Hetu: Loaded libary [${path.basename(file.path)}].');
            eval(file.readAsStringSync());
          }
        }

        globalContext.bindAll(HetuBuildInFunction.bindmap);
        globalContext.bindAll(bindMap);
        globalContext.linkAll(HetuBuildInFunction.linkmap);
        globalContext.linkAll(linkMap);

        _init = true;
      }

      if (context != null) {
        if (preloadDir != null) {
          print('Hetu: Preload directory set to [$preloadDir].');
          dirObj = Directory(preloadDir);
          fileList = dirObj.listSync();
          for (var file in fileList) {
            if (file is File) {
              print('Hetu: loading script file [${path.basename(file.path)}]...');
              eval(file.readAsStringSync(), context: context);
            }
          }
        }

        context.bindAll(HetuBuildInFunction.bindmap);
        context.bindAll(bindMap);
        context.linkAll(HetuBuildInFunction.linkmap);
        context.linkAll(linkMap);
      }
    } catch (e) {
      print(e);
      print('Hetu init failed!');
    }
  }

  static void bind(String name, Call function, {Context context}) {
    var ctx = context ?? globalContext;
    ctx.bind(name, function);
  }

  static void invoke(String name, {Context context, List<HS_Instance> args}) {
    HS_Error.clear();
    var ctx = context ?? globalContext;
    try {
      ctx.invoke(name, args: args);
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  static void eval(String script,
      {Context context, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<HS_Instance> args}) {
    var ctx = context ?? globalContext;

    HS_Error.clear();
    try {
      var commandLine = ((style == ParseStyle.commandLine) || (style == ParseStyle.commandLineScript));
      final _lexer = Lexer();
      final _parser = Parser();
      final _resolver = Resolver();
      var tokens = _lexer.lex(script, commandLine: commandLine);
      var statements = _parser.parse(tokens, context: context, style: style);
      _resolver.resolve(statements, context: context);
      ctx.interpreter(
        statements,
        commandLine: commandLine,
        invokeFunc: invokeFunc,
        args: args,
      );
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  /// 解析文件
  static void evalf(String path,
          {Context context, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<HS_Instance> args}) =>
      eval(File(path).readAsStringSync(), context: context, style: style, invokeFunc: invokeFunc, args: args);

  /// 解析多个文件
  static void evalfs(Set<String> paths,
      {Context interpreter, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<HS_Instance> args}) {
    String chunk = '';
    for (var file in paths) {
      chunk += File(file).readAsStringSync();
    }
    eval(chunk, context: interpreter, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  static void evalfs2(List<FileSystemEntity> paths,
      {Context interpreter, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<HS_Instance> args}) {
    String chunk = '';
    for (var file in paths) {
      if (file is File) chunk += file.readAsStringSync();
    }
    eval(chunk, context: interpreter, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析命令行
  static void evalc(String commandLine, {List<HS_Instance> args}) =>
      eval(commandLine, args: args, style: ParseStyle.commandLine);
}
