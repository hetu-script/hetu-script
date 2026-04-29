# AI Agent Instructions — Hetu Script

## Project Overview

Hetu Script is a lightweight scripting language written in Dart, designed for embedding in Flutter apps. It runs on all Flutter-supported platforms.

- **Website**: https://hetu.dev
- **Docs (EN)**: https://hetu.dev/docs/en-US/
- **Online playground**: https://hetu.dev/codepad/

## Monorepo Structure

| Package                 | Path                              | Purpose                                                                            |
| ----------------------- | --------------------------------- | ---------------------------------------------------------------------------------- |
| `hetu_script`           | `packages/hetu_script/`           | Core language implementation (lexer, parser, AST, analyzer, compiler, interpreter) |
| `hetu_script_dev_tools` | `packages/hetu_script_dev_tools/` | CLI REPL tool and file system integration                                          |
| `hetu_script_flutter`   | `packages/hetu_script_flutter/`   | Flutter asset loading via `initFlutter()`                                          |
| `hetu_script_code_pad`  | `packages/hetu_script_code_pad/`  | Flutter Web playground                                                             |

Standard library sources live in `lib/*.ht` and are precompiled into `packages/hetu_script/lib/precompiled_module.dart`.

## Build & Test

```bash
# Build: compile standard library + activate CLI tool
python build.py
# Or manually:
dart run utils/compile_hetu.dart   # generates precompiled_module.dart
dart pub global activate --source path packages/hetu_script_dev_tools

# Run all tests
dart test

# Run specific test suite
dart test test/interpreter/base_test.dart

# Run the CLI REPL
dart pub global run hetu_script_dev_tools:cli_tool
```

After modifying any `lib/*.ht` standard library file, re-run `dart run utils/compile_hetu.dart` to regenerate the precompiled module.

## Compiler Pipeline

```
Source (.ht/.hts) → Lexer → Parser → AST → Analyzer → Compiler → Bytecode → Interpreter
```

Key directories under `packages/hetu_script/lib/`:

| Directory      | Role                                                              |
| -------------- | ----------------------------------------------------------------- |
| `lexer/`       | Tokenization (`HTLexer`)                                          |
| `parser/`      | AST generation (`HTParser`)                                       |
| `ast/`         | AST node definitions + visitor pattern                            |
| `analyzer/`    | Static type checking (`HTAnalyzer`)                               |
| `bytecode/`    | Bytecode compiler, opcodes, reader                                |
| `interpreter/` | Bytecode/AST execution (`HTInterpreter`)                          |
| `bundler/`     | Import resolution and module bundling                             |
| `value/`       | Runtime values (objects, instances, structs, functions)           |
| `type/`        | Type system (nominal, structural, union, literal, function types) |
| `declaration/` | Declaration nodes (class, function, variable, namespace)          |
| `external/`    | Dart↔Hetu binding (external classes, functions, typedefs)         |
| `formatter/`   | Code formatter                                                    |
| `error/`       | Error codes and error handler                                     |
| `resource/`    | Source file management and overlay (virtual) file system          |

## Architecture Patterns

- **Visitor pattern** for AST traversal: `AbstractASTVisitor<T>`, `RecursiveASTVisitor<T>`
- **Mixin pattern**: `HTObject` for value member access
- **Main entry point**: `Hetu` class in `packages/hetu_script/lib/preinclude/hetu.dart` with `HetuConfig`
- **Public API export**: `packages/hetu_script/lib/hetu_script.dart`

## Conventions

- **Linting**: `package:lints/recommended.yaml` (see [analysis_options.yaml](packages/hetu_script/analysis_options.yaml))
- **File naming**: Implementation files use `_hetu` suffix (e.g., `lexer_hetu.dart`); base/interface files have no suffix
- **Test files**: `_test.dart` suffix, organized by component under `test/`
- **Hetu script files**: `.ht` (module/library), `.hts` (script with top-level statements)

## External Binding System

To bind Dart code into Hetu:

- **Functions**: Register via `externalFunctions` map on `Hetu.init()`
- **Classes**: Extend `HTExternalClass` and implement `instanceMemberGet`/`instanceMemberSet`
- **Typedefs**: Use `HTExternalFunctionTypedef` to bridge Hetu functions to Dart callbacks
- See `examples/external_*.dart` for patterns

## Documentation

- Language grammar and guide: [docs/docs/en-US/](docs/docs/en-US/)
- Chinese docs: [docs/docs/zh-Hans/](docs/docs/zh-Hans/)
- Package READMEs: each package has its own [README.md](packages/hetu_script/README.md)
- Usage examples: [examples/](examples/)
