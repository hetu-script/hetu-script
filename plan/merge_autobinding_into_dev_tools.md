# Autobinding 迁移合并计划

## 文档说明

本计划用于将平行项目 `hetu-script-autobinding` 的核心能力迁移到 `hetu_script_dev_tools` 中，形成统一的自动绑定代码生成方案。

状态：待执行。本阶段只输出计划，不修改实现代码。

迁移原则：以 autobinding 的“解析 Dart 代码 → 生成绑定”思路为参考，按当前 Hetu API、Dart 3 语言特性和 Dart 生态主流代码生成方式重写，不直接搬运旧实现。

## 目标与非目标

### 目标

- 在 `hetu_script_dev_tools` 中实现自动绑定生成能力，为标记 `@HTBinding()` 的 Dart 类/枚举生成绑定代码。
- 生成产物与当前 `HTExternalClass` API 匹配，可直接用于 `Hetu.init(externalClasses: [...])`。
- 同时生成对应的 `.ht` external class 声明脚本。
- 提供两种使用方式：
  - **build_runner 集成**：符合 Dart/Flutter 生态标准，支持增量生成和 CI；
  - **hetu bind CLI**：用于快速生成、非标准项目或调试。
- 核心逻辑做成独立库，CLI 和 build_runner 共用同一套实现。
- 实现可测试、可维护，避免全局可变状态和进程级副作用。

### 非目标

- 不直接合并 autobinding 旧代码。
- 不默认支持 Flutter/Dart SDK 全量绑定。
- 不改变 `hetu_script` 核心绑定 API。
- 不引入新的脚本语法或注解体系；继续使用已有的 `@HTBinding()`。
- 不在首版支持所有 Dart 语言特性；对不支持的特性明确跳过并输出诊断。
- 不将 Dart 宏（Macros）作为首版实现方案。

## 现状分析

### autobinding 架构

- 入口：`lib/main.dart`，基于 `args` 解析 `-u/-p/-f/-o/-s` 等参数。
- AST 解析：`lib/dart-visitor.dart`，使用 `package:analyzer` 将 Dart AST 转为 Map/JSON。
- 语义模型：`lib/defines.dart`，包含 `ClassDefine`、`MethodDefine`、`FieldVarDefine`、`FunctionTypeDefine` 等。
- 代码生成：`lib/binding-generator.dart`，使用 Mustache 模板生成 `.g.dart` 和 `.ht` 文件。
- 模板：`bin/template/*.mustache`，同时内置默认模板字符串。

### dev_tools 现状

- CLI 入口：`packages/hetu_script_dev_tools/bin/cli_tool.dart`。
- 已有子命令：`run`、`format`、`analyze`、`compile`。
- 公共状态：`bin/common.dart` 中维护 `sourceContext`、`hetu`、`analyzer`、`bundler` 等。
- 依赖：`args`、`path`、`http`、`pub_semver`，以及本地 `hetu_script`。

### 关键差异

| 项目 | autobinding | 当前 dev_tools / hetu_script |
| --- | --- | --- |
| Dart SDK | `>=2.12.0 <3.0.0` | `>=3.0.0 <4.0.0` |
| hetu_script | `^0.4.2+1` | 本地路径，当前 0.7.x/0.8.x |
| analyzer | `^4.7.0` | 需升级到与 Dart 3.x 兼容的版本 |
| 绑定基类 | `HTExternalClass`（旧签名） | `HTExternalClass`（新签名） |
| 函数签名 | 包含 `HTEntity`、`typeArgs` | 仅 `positionalArgs`、`namedArgs` |
| 实例方法 | 返回闭包接收 `HTEntity` | 返回闭包接收 `object` 或使用 `instance` |
| 代码风格 | 大量全局可变状态、动态类型、print 调试 | 更严格的类型和 lint |
| 生成方式 | 仅 CLI | 应支持 build_runner + CLI |

## 技术方案选择

### 核心架构：生成库 + build_runner + CLI

采用 Dart 生态标准的代码生成架构：

```
packages/hetu_script_dev_tools/
  lib/src/binding/
    binding_generator.dart      # 核心生成逻辑（库）
    binding_resolver.dart       # 基于 resolved AST 的语义提取
    binding_models.dart         # sealed class / record 模型
    binding_emitter.dart        # 代码输出（code_builder 或模板）
  bin/cli_tool.dart             # 新增 bind 子命令，调用核心库
  build.yaml                    # build_runner 配置
```

- **核心库**：不依赖 CLI 或 build_runner，可独立测试。
- **build_runner 集成**：实现 `GeneratorForAnnotation<HTBinding>`，用户运行 `dart run build_runner build` 即可生成。
- **CLI 包装**：`hetu bind` 调用同一核心库，适合快速生成和非标准项目。

### 语义分析：使用 Resolved AST 而非纯语法 AST

autobinding 使用 `parseFile` 只做语法解析，导致继承、类型、泛型处理脆弱。本计划改用 `AnalysisContextCollection`：

- 获取 `ResolvedUnitResult`，直接访问 `ClassElement`、`MethodElement`、`PropertyAccessorElement`；
- 自动获得已解析的类型、继承链、泛型、默认值信息；
- 避免手动拼接 `superClass`、处理 mixin/extension 等复杂逻辑。

### 语义模型：使用 Dart 3 现代特性

- 用 `sealed class` 表示绑定节点类型（`BindingClass`、`BindingEnum`、`BindingFunctionType`）；
- 用 `record` 封装解析结果和参数信息，避免 `Map<String, dynamic>`；
- 用 `pattern matching` 处理不同声明类型；
- 模型保持不可变，使用 `final` 字段和构造函数初始化。

### 代码生成：优先 `code_builder`，模板作为备选

- 首选 `package:code_builder`：在 Dart AST 级别构建代码，自动处理导入、格式化、转义，减少语法错误。
- 备选 Mustache：如果团队更熟悉模板，可保留模板方案，但生成后必须经 `dart format` 和 `dart analyze` 验证。
- `.ht` 脚本声明可直接字符串生成，语法简单，无需复杂模板。

### Dart 宏：仅作为未来选项

Dart 宏若已稳定，长期可替代 build_runner 方案。但首版不依赖宏，避免实验性 API 风险。

## 命令设计

### build_runner 方式（推荐）

用户在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  hetu_script: ^x.x.x

dev_dependencies:
  hetu_script_dev_tools: ^x.x.x
  build_runner: ^x.x.x
```

在 Dart 类上添加注解：

```dart
import 'package:hetu_script/binding.dart';

@HTBinding()
class Person { ... }
```

运行：

```bash
dart run build_runner build
```

生成产物默认输出到 `lib/` 同级或指定目录。

### CLI 方式

```bash
hetu bind [options]
```

首版选项：

- `-u, --user-lib-paths=<path1,path2,...>`：用户 Dart 源码目录，递归扫描。
- `-o, --output=<path>`：生成的 `.g.dart` 输出目录，默认 `gen/dart`。
- `-s, --script-output=<path>`：生成的 `.ht` 输出目录，默认 `gen/ht`。
- `-i, --ignores=<pattern1,pattern2,...>`：忽略文件或类。
- `-w, --whitelist=<pattern1,pattern2,...>`：只处理匹配文件。
- `-j, --json-export=<path>`：可选，导出中间语义模型用于诊断。
- `-h, --help`：显示帮助。

后续可选选项（不在首版实现）：

- `-p, --package-lib-paths`：第三方 package 绑定。
- `-f, --flutter-lib-path`：Flutter SDK 绑定。

## 实施阶段

### 阶段一：核心生成库与语义模型

工作内容：

- 在 `packages/hetu_script_dev_tools` 新增 `lib/src/binding/` 目录。
- 添加依赖：`analyzer`（Dart 3.x 兼容版本）、`code_builder`（或 `mustache_template`）、`source_gen`（用于 build_runner 集成）。
- 实现不可变语义模型：
  - `BindingClass`
  - `BindingEnum`
  - `BindingConstructor`
  - `BindingMethod`
  - `BindingField`
  - `BindingFunctionType`
- 使用 `AnalysisContextCollection` 解析指定文件，获取 `ResolvedUnitResult`。
- 实现语义提取器，从 `ClassElement` / `EnumElement` 构建模型。
- 只处理 `@HTBinding()` 标记的公开类/枚举；私有、protected、deprecated 成员跳过。

验收：

- 能解析 `examples/external_class.dart` 中的 `Person` 类并生成中间模型。
- 模型包含构造函数、静态/实例方法、字段、getter/setter。
- 单元测试覆盖语义提取和模型构建。

### 阶段二：代码生成与当前 API 适配

工作内容：

- 使用 `code_builder` 或模板生成符合当前 API 的 `HTExternalClass` 子类。
- 生成 `memberGet` / `memberSet` 处理静态成员和构造函数。
- 生成 `instanceMemberGet` / `instanceMemberSet` 处理实例成员。
- 方法闭包签名使用 `{positionalArgs, namedArgs}`，实例方法使用 `object` 参数。
- 生成 `.ht` external class 声明。
- 处理 Hetu 关键字别名（如 `var` → `var_alias`）。
- 处理可选参数默认值、命名参数、基本类型转换。
- 生成后自动执行 `dart format`。

验收：

- 生成的 `PersonClassBinding` 与 `examples/external_class.dart` 手写版本行为一致。
- 生成代码通过 `dart analyze`。
- 生成代码能在 `Hetu.init(externalClasses: [...])` 中注册并执行脚本。

### 阶段三：build_runner 集成

工作内容：

- 实现 `HTBindingGenerator extends GeneratorForAnnotation<HTBinding>`。
- 配置 `build.yaml`，声明生成器和输出扩展名。
- 支持自定义输出路径和生成选项。
- 处理 build_runner 的增量构建和缓存语义。

验收：

- 示例项目运行 `dart run build_runner build` 能生成绑定。
- 修改 Dart 源码后重新生成结果正确。
- 生成文件不会冲突或重复。

### 阶段四：CLI 集成

工作内容：

- 在 `bin/cli_tool.dart` 的 `initargParser()` 中注册 `bind` 子命令。
- 实现 `bind(List<String> args, ...)` 函数，调用核心生成库。
- 复用现有 `info()` 输出和错误处理。
- 更新 `cliHelp` 文本。
- 处理相对路径、输出目录创建、文件写入。

验收：

- `hetu bind -h` 显示帮助。
- `hetu bind -u example/binding -o gen/dart -s gen/ht` 能生成文件。
- 无效参数有明确错误提示。

### 阶段五：测试与验证

工作内容：

- 在 `packages/hetu_script_dev_tools/test/` 新增绑定生成测试。
- 准备测试用 Dart 源码，覆盖：
  - 普通类、命名构造函数、工厂构造函数；
  - 静态方法/字段、实例方法/字段；
  - getter/setter；
  - 枚举；
  - 可选参数、命名参数、默认值；
  - `@HTBinding()` 过滤；
  - 忽略/白名单。
- 集成测试：分别通过 build_runner 和 CLI 生成绑定，用 `Hetu` 实际加载并执行脚本。
- 运行全量 `dart test` 确保 dev_tools 和核心包无回归。
- 运行 `dart analyze` 和格式检查。

验收：

- 所有新增测试通过。
- 全量测试无回归。
- 生成代码无 lint 错误。
- build_runner 和 CLI 生成结果一致。

### 阶段六：可选扩展（暂缓）

以下内容不在首版范围内，根据实际需求再决定是否实施：

- 第三方 package 绑定（`-p`）。
- Flutter/Dart SDK 绑定（`-f`）。
- 函数 typedef 自动桥接（`HTExternalFunctionTypedef`）。
- extension 和 mixin 成员合并。
- 泛型类特化绑定。
- Dart 宏实现。
- 自定义模板/emitter 覆盖。

## 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| analyzer/source_gen 版本与 Dart 3.x 不兼容 | 无法解析或集成 build_runner | 使用当前稳定版，并在 CI 中验证 |
| 生成代码与运行时 API 不匹配 | 绑定无法使用 | 以 `examples/external_class.dart` 为黄金参照，做端到端测试 |
| Dart 语法特性覆盖不全 | 部分类生成失败 | 首版明确支持范围，不支持的特性跳过并诊断 |
| 全局状态导致多次生成互相污染 | 结果不可预测 | 使用不可变模型和实例级上下文，禁止静态可变缓存 |
| 依赖增加导致 dev_tools 变重 | 影响 CLI 启动和分发 | 核心生成库按需加载；CLI 其他命令不引入 analyzer/source_gen |
| build_runner 与 CLI 行为不一致 | 用户体验割裂 | 两者共用同一核心库，测试覆盖两种入口 |

## 验收标准

首版完成需满足：

1. 核心生成库可独立使用，能处理 `@HTBinding()` 类/枚举。
2. build_runner 集成可用，`dart run build_runner build` 能生成绑定。
3. `hetu bind` CLI 可用，与 build_runner 生成结果一致。
4. 生成代码符合当前 `HTExternalClass` API，可直接注册使用。
5. 生成 `.ht` 声明脚本可被 Hetu 解析。
6. 新增单元测试和集成测试全部通过。
7. 全量 `dart test` 无回归。
8. 生成代码通过 `dart analyze` 和 `dart format`。
9. 文档更新：`packages/hetu_script_dev_tools/README.md` 增加两种使用方式说明。

## 后续可选工作

- 根据用户反馈扩展 package 绑定能力。
- 支持更多 Dart 特性（extension、mixin、泛型、typedef）。
- 提供 VS Code 任务或构建脚本集成。
- 评估 Dart 宏作为下一代实现方案。
- 将核心生成器拆分为独立 package，供其他构建工具调用。
