# Hetu Script command line tool

A command line REPL tool for testing.

## Installation

You can install this tool globally with `dart install`:

```
dart install https://github.com/hetu-script/hetu-script.git --git-path packages/hetu_script_dev_tools
```

Or install from a local path:

```
dart install --source path /path/to/hetu-script/packages/hetu_script_dev_tools
```

Then you can use command line tool 'hetu' in any directory on your computer.

(If you are facing any problems, please check this official document about [dart install](https://dart.dev/tools/dart-install))

## REPL

If no arguments is provided when execute, the command tool will enter REPL mode.

In REPL mode, every exrepssion you entered will be evaluated and print out immediately.

If you want to write multiple line in REPL mode, use '\\' to end a line.

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

## Run

Run a Hetu source file on your disk. The file could be a script source or a compiled bytecode.

```
hetu run [path]
```

## Format

Format a Hetu source file on your disk and save the result to file.

```
hetu format [path] [option]
      --out(-o) [outpath]
```

## Compile

Compile a Hetu source file on your disk into bytecode.

```
hetu compile [path] [output_path] [option]
```

## Analyze

Analyze a Hetu source file on your disk. List all warnings and errors.

```
hetu analyze [path]
```
