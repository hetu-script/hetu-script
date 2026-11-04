# 命令行工具

河图提供了一个命令行工具来辅助测试和开发。

## 安装

只需要使用下面的命令，在你的机器上安装一个全局 Dart 脚本，即可使用这个命令行工具：

```
dart pub global activate hetu_script_dev_tools
// or you can use a git url or local path:
// dart pub global activate --source path G:\_dev\hetu-script\dev-tools
```

安装之后，你就可以在任意目录下使用 **hetu** 命令。

(关于 Dart 这个全局脚本的用法，可以参考 [dart pub global activate](https://dart.dev/tools/pub/cmd/pub-global))。

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
