# 命令行工具

河图提供了一个命令行工具来辅助测试和开发。

## 安装

使用 `dart install` 命令即可在你的机器上全局安装这个命令行工具：

```
dart install https://github.com/hetu-script/hetu-script.git --git-path packages/hetu_script_dev_tools
```

也可以从本地路径安装：

```
dart install --source path /path/to/hetu-script/packages/hetu_script_dev_tools
```

安装之后，你就可以在任意目录下使用 **hetu** 命令。

(关于 `dart install` 的用法，可以参考 [官方文档](https://dart.dev/tools/dart-install))。

## REPL

如果执行 **hetu** 命令时没有提供任何参数，将会进入 **REPL** 模式。

REPL 的意思是 Read–Eval–Print Loop。在这个模式下，你可以直接键入一个脚本表达式或者语句，它的值将会立即被打印到屏幕上。

如果你需要多行输入，使用 '\\' 来结束一行。

```typescript
>>>var a = 42
>>>a
42
>>>function hello {\
return a }
>>>hello
function hello() -> any // repl print
>>>hello()
42 // repl print
>>>
```

## run

运行一个字符串或者一个字节码形式的脚本代码。

```
hetu run [path]
```

## format

格式化一个字符串形式的脚本代码，并且另存到 --out 选项所指定的路径。

```
hetu format [path] [option]
      --out(-o) [outpath]
```

## compile

将一个字符串形式的脚本编译为字节码形式的代码。

```
hetu compile [path] [output_path] [option]
```

## analyze

对一个字符串形式的脚本代码进行静态分析，然后打印所有的警告或者错误。

```
hetu analyze [path]
```

## bind

为标记了 `@HTBinding()` 的 Dart 类、枚举和函数 typedef 生成外部绑定代码。

```
hetu bind -u [path1,path2,...] [option]
```

选项：

- `-u, --user-lib-paths`：包含 Dart 源代码的目录，会递归扫描。
- `-o, --output`：生成的 `.g.dart` 文件的输出目录（默认：`gen/dart`）。
- `-s, --script-output`：生成的 `.ht` 声明文件的输出目录（默认：`gen/ht`）。
- `-i, --ignores`：要忽略的文件或类名模式。
- `-w, --whitelist`：只处理匹配这些模式的文件。

示例：

```bash
hetu bind -u lib/src -o gen/dart -s gen/ht
```
