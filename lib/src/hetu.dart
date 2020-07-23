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

class Hetu {
  static List<String> _coreLib = [
    'literals.ht',
    'system.ht',
  ];

  Context _before;
  Context _context = Context();

  /// Only call this method if you are switching between different contexts.
  void close() {
    globalContext = _before;
  }

  Hetu({
    String sdkDir = 'hetu_core',
    List<String> importDir,
    String language = 'enUS',
    Map<String, HS_External> bindMap,
    Map<String, HS_External> linkMap,
  }) {
    _before = globalContext;
    globalContext = _context;

    try {
      Directory dirObj;
      List<FileSystemEntity> fileList;
      String libpath;

      // 加载河图基础对象
      print('Hetu: Core library path set to [${HS_Common.coreLibPath}].');
      libpath = path.join(sdkDir, 'object.ht');
      evalf(libpath);
      print('Hetu: Loaded core libary [object.ht].');

      // 绑定外部函数
      globalContext.bindAll(HS_Extern.bindmap);
      globalContext.bindAll(bindMap);
      globalContext.linkAll(HS_Extern.linkmap);
      globalContext.linkAll(linkMap);

      // 加载核心库
      for (var lib in _coreLib) {
        libpath = path.join(sdkDir, lib);
        evalf(libpath);
        print('Hetu: Loaded core libary [$lib].');
      }

      // TODO：使用import关键字决定加载顺序，而不是现在这样简单粗暴的遍历
      // 加载本次脚本文件需要的库
      if (importDir != null) {
        for (var dir in importDir) {
          dirObj = Directory(dir);
          fileList = dirObj.listSync();
          for (var file in fileList) {
            if (file is File) {
              eval(file.readAsStringSync());
              print('Hetu: Impoted file [${path.basename(file.path)}].');
            }
          }
        }
      }
    } catch (e) {
      print(e);
      print('Hetu init failed!');
    }
  }

  void bind(String name, HS_External function) {
    _context.bind(name, function);
  }

  dynamic invoke(String name, {String classname, List<dynamic> args}) {
    HS_Error.clear();
    try {
      return _context.invoke(name, classname: classname, args: args);
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  void eval(String script, {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    HS_Error.clear();
    try {
      final _lexer = Lexer();
      final _parser = Parser();
      final _resolver = Resolver();
      var tokens = _lexer.lex(script);
      var statements = _parser.parse(tokens, context: globalContext, style: style);
      _resolver.resolve(statements, context: globalContext);
      globalContext.interpreter(
        statements,
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
  void evalf(String path, {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    print('Hetu: Processing $path');
    eval(File(path).readAsStringSync(), style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  void evalfs(Set<String> paths,
      {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      chunk += File(file).readAsStringSync();
    }
    eval(chunk, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  void evalfs2(List<FileSystemEntity> paths,
      {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      if (file is File) chunk += file.readAsStringSync();
    }
    eval(chunk, style: style, invokeFunc: invokeFunc, args: args);
  }

  var clReg = RegExp(r"('(\\'|[^'])*')|(\S+)");

  /// 解析命令行
  dynamic evalc(String input) {
    var matches = clReg.allMatches(input);
    var function = matches.first.group(3);
    String classname;
    if (function == null) throw Exception('命令行错误：无效的调用。');
    if (function.contains('.')) {
      var split = function.split('.');
      function = split.last;
      classname = split.first;
    }
    var args = <String>[];
    for (var i = 1; i < matches.length; ++i) {
      var word = matches.elementAt(i);
      if (word.group(1) != null) {
        String literal = word.group(1);
        literal = literal.substring(1).substring(0, literal.length - 2);
        args.add(literal);
      } else {
        args.add(word.group(0));
      }
    }
    return invoke(function, classname: classname, args: args);
  }
}
