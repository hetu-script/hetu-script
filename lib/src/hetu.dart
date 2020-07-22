import 'dart:io';

import 'package:path/path.dart' as path;

import 'errors.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';
import 'interpreter.dart';
import 'external.dart';
import 'function.dart';
import 'common.dart';

abstract class Hetu {
  static var _init = false;
  static bool get isInit => _init;

  static void init({
    Context context,
    String sdkDir = 'hetu_core',
    String importDir,
    String language = 'enUS',
    Map<String, HS_External> bindMap,
    Map<String, HS_External> linkMap,
  }) {
    try {
      Directory dirObj;
      List<FileSystemEntity> fileList;
      File file;
      String libpath;

      if ((!isInit) && (context != null)) {
        init(sdkDir: sdkDir, language: language, bindMap: bindMap, linkMap: linkMap);
        _init = true;
      }

      // 加载河图本身的核心库
      print('Hetu: Core library path set to [${HS_Common.coreLibPath}].');
      libpath = path.join(sdkDir, 'object.hs');
      file = File(libpath);
      eval(file.readAsStringSync(), context: context);
      print('Hetu: Loaded libary [object.hs].');

      // 绑定外部函数
      context.bindAll(HS_Extern.bindmap);
      context.bindAll(bindMap);
      context.linkAll(HS_Extern.linkmap);
      context.linkAll(linkMap);

      libpath = path.join(sdkDir, 'literals.hs');
      file = File(libpath);
      eval(file.readAsStringSync(), context: context);
      print('Hetu: Loaded libary [literals.hs].');

      // 加载本次脚本文件需要的库
      dirObj = Directory(importDir);
      fileList = dirObj.listSync();
      for (var file in fileList) {
        if (file is File) {
          eval(file.readAsStringSync(), context: context);
        }
      }
    } catch (e) {
      print(e);
      print('Hetu init failed!');
    }
  }

  static void bind(String name, HS_External function, {Context context}) {
    var ctx = context ?? globalContext;
    ctx.bind(name, function);
  }

  static void invoke(String name, {Context context, List<dynamic> args}) {
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
      {Context context, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<dynamic> args}) {
    var ctx = context ?? globalContext;
    if (!_init) print('Hetu: (warning) evironment is not initialized yet.');

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
          {Context context, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<dynamic> args}) =>
      eval(File(path).readAsStringSync(), context: context, style: style, invokeFunc: invokeFunc, args: args);

  /// 解析多个文件
  static void evalfs(Set<String> paths,
      {Context interpreter, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      chunk += File(file).readAsStringSync();
    }
    eval(chunk, context: interpreter, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  static void evalfs2(List<FileSystemEntity> paths,
      {Context interpreter, ParseStyle style = ParseStyle.program, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      if (file is File) chunk += file.readAsStringSync();
    }
    eval(chunk, context: interpreter, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析命令行
  static void evalc(String commandLine, {List<dynamic> args}) =>
      eval(commandLine, args: args, style: ParseStyle.commandLine);
}
