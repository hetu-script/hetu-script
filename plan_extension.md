# 计划：`extension` 关键字 —— 显式扩展 namespace / class / named struct

> 状态：**Phase 1（extension on namespace）已实现**（见文末实现记录）。
> Phase 2（class）、Phase 3（named struct）保留待做。
> 本方案取代了更早的"同名 namespace 静默合并"计划（旧计划文件已删除）。

## 1. 目标

新增关键字 `extension`（借鉴 Dart 扩展方法的写法），允许用户显式地为
**namespace、class、named struct** 扩充成员，**仅限方法**。典型用途：
扩展 import 进来的命名空间，向其中添加工具函数。

语法（已与需求方确认）——目标种类**显式写出**，编译期可知：

```dart
extension namespace MySpace {     // 扩展 import 进来的命名空间
  fun helper() { ... }
}

extension class MyClass {         // 扩展类（实例方法）
  fun extraMethod() { ... }
}

extension struct MyStruct {       // 扩展 named struct（Phase 3）
  fun extraMethod() { ... }
}
```

`namespace` / `class` / `struct` 均为现有关键字，parser 在 `extension` 后读一个
关键字即可静态确定目标种类，**无需新增除 `extension` 外的任何关键字**。

已确认的决策：

- **显式扩展，不做静默合并**（同名 namespace 跨文件自动合并的方案废弃）。
- **仅限方法**：extension 块体内只允许函数声明，解析期强制。
- **目标可见性**：扩展目标必须在定义处可见（本地符号或经 import 链可见）——
  保留"import 作用域"原则，无 import 关系的目标不可扩展。
- **成员冲突**：扩展方法与目标已有成员同名 → 抛 `HTError.defined`，不允许覆盖。
- **分期实现**：Phase 1 namespace → Phase 2 class → Phase 3 named struct。

## 2. 核心语义：运行时注入（与 Dart 的本质差异）

Dart 的扩展方法是纯静态的（编译期解析，运行时不存在）。Hetu 的分析器默认关闭、
成员查找全部走运行时 `memberGet`，因此 Hetu 的 extension 采用**运行时注入**语义：

- extension 块执行时，把其中的方法**真正写入目标的符号表**
  （更接近 Ruby open class / C# partial，而非 Dart extension）。
- 对 class 的扩展：方法写入 class 的命名空间后，由于实例 `memberGet`
  在调用时刻动态解析（`instance.dart:161-187`，且会动态设置
  `decl.namespace`/`decl.instance = this`，:184-185），
  **所有实例（包括扩展执行前已创建的）立即可用**，`this` 绑定自动生效。
- 注入效果在解释器会话内全局生效；但注入的前提（目标可见）仍由 import 关系约束。
- 文档需明确写出与 Dart 的这一差异。

## 3. 现状与改动点

### 3.1 可直接复用的既有机制

| 既有实现 | 位置 | 复用方式 |
|---|---|---|
| `namespace id { ... }` 解析 | `parser/parser_hetu.dart:2799` `_parseExplicitNamespaceDecl` | extension 解析的模板 |
| `NamespaceDecl` AST | `ast/ast.dart:1565` | `ExtensionDecl` 节点的模板 |
| `OpCode.namespaceDecl/End` | `bytecode/op_code.dart:41-42`；编译 `compiler.dart:1564-1587`；执行 `interpreter.dart:1522-1551` | 新 opcode 对 `extensionDecl/End` 的模板 |
| 目标符号表注入 | `HTDeclarationNamespace.define()`（`declaration/namespace/declaration_namespace.dart:60`）自带重名检查 | 冲突报错直接复用 |
| class 实例动态成员解析 | `value/instance/instance.dart:161-187` | class 扩展"已有实例即可用"免改 |
| class 的命名空间 | `value/class/class.dart:43`（`HTClassNamespace`） | class 扩展的注入目标 |

### 3.2 需要新增/修改的部分

1. **lexicon**：`lexicon.dart` + `lexicon_hetu.dart` 增加 `kExtension = 'extension'`。
2. **parser**：`_parseExtensionDecl`——`extension` 后读种类关键字（namespace/class/struct）
   再读目标 id + 块体，块体内仅允许函数声明；按种类选择块体的 ParseStyle
   （`extension class` 的块体按 `ParseStyle.classDefinition` 解析，内部函数直接
   编译为带 `this` 语义的方法；`extension namespace` 按普通块解析）。
   允许出现的位置与 namespace 相同（模块/脚本顶层、namespace 块内）。
3. **AST**：新增 `ExtensionDecl extends Statement`（字段：`targetKind`（枚举）、
   `targetId`、`definition: BlockStmt`）。
   **注意样板成本**：`AbstractASTVisitor`、`RecursiveASTVisitor`、analyzer（2 个 visitor）、
   compiler、formatter 均需加 `visitExtensionDecl`，约 6-8 个文件。
4. **字节码**：新增 `OpCode.extensionDecl / extensionDeclEnd`
   （载荷：targetKind 一字节 + targetId），追加在 op_code.dart 末尾避免重编号；
   **升字节码版本**并运行 `python buildlib.py`（或 `dart run utils/compile_hetu.dart`）
   重新生成 `packages/hetu_script/lib/precompiled_module.dart`。
5. **interpreter**：`extensionDecl` 分支——按 targetId 在 currentNamespace 的
   `symbols` + `importedSymbols`（递归沿 closure 链）解析目标，
   **校验解析到的目标种类与声明的 targetKind 一致**（不一致报明确错误），
   然后把函数定义重定向进目标符号表；`extensionDeclEnd` 恢复现场。

### 3.3 各 Phase 的具体设计

**Phase 1：extension on namespace（直接服务最初目标）**

- interpreter：解析到的目标为 `HTNamespace` → 压栈为 currentNamespace
  （与 namespaceDecl 相同的机制），块内函数自然 define 进目标；
  重名由 `define()` 现有检查抛 `HTError.defined`。
- 块内函数保持普通函数字面量 category（namespace 成员本就如此），无需特殊处理。
- 目标解析失败（未定义/不可见/类型不符）→ 明确报错信息（新 error code 或复用 undefined）。

**Phase 2：extension on class**

- 目标种类编译期已知（`extension class`），parser 直接按 `ParseStyle.classDefinition`
  解析块体，内部函数自然编译为方法（method category、带 `this` 语义）——
  原决策点 A 的难度已消除。
- 运行时：目标为 `HTClass` → 函数 define 进其 `HTClassNamespace`（class.dart:43）。
  实例调用路径（instance.dart）自动完成 this 绑定，无需改动。
- 明确不支持：构造函数、静态成员、字段——仅普通方法。
  get/set 是否允许：**决策点 B**（倾向第一版只允许普通方法）。

**Phase 3：extension on named struct（有坑，独立评估后再做）**

- struct 是原型链结构（`struct.dart:163` 沿 prototype 查找）；匿名字面量无名可指，
  扩展目标只能是 `HTNamedStruct`（`value/struct/named_struct.dart:14`）。
- 坑：named struct 创建对象走 `_self.clone()`（named_struct.dart:63）——
  若 clone 拷贝字段，则**扩展只影响之后创建的对象**，已创建对象看不到新方法。
- 决策点 C（Phase 3 启动时先调查 clone 语义再定）：
  - 注入 `_self`，文档说明"只影响扩展执行后创建的对象"（简单）；
  - 或注入原型层使既有对象也可见（需验证 `createObject` 的 clone/prototype 链接方式，可能改动 clone 行为）。

### 3.4 明确不做

- 不做静态解析式 extension（Dart 语义）——与 Hetu 动态架构不符。
- 不允许扩展外部类（external class）——其成员由 Dart 侧绑定，注入无意义；
  解析到 external 目标时报错。
- Analyzer 本期不做特殊支持（默认关闭；`visitExtensionDecl` 走 subAccept 即可）。

## 4. 实施步骤（按 Phase）

每期公共步骤：lexicon/parser/AST/visitor/字节码/interpreter 改动 + 测试 + `dart test` 全量回归。

**Phase 1**
1. lexicon 加 `kExtension`；parser `_parseExtensionDecl`；AST `ExtensionDecl` + 全部 visitor。
2. op_code 追加 `extensionDecl/extensionDeclEnd`；compiler `visitExtensionDecl`；
   interpreter 两个新 opcode 分支（目标解析 + 类型校验 + 压栈/弹栈）。
3. 升字节码版本，`python buildlib.py` 重新生成 precompiled module。
4. formatter 支持新语法。
5. 测试（新增 `test/interpreter/extension_test.dart` 或按现有目录惯例）：
   - 扩展 import 进来的 namespace 后可调用新方法；原有方法不受影响；
   - 目标未定义/不可见 → 报错；目标类型不符（对 class/struct 在 Phase 1 先报错）→ 报错；
   - 与既有成员重名 → `HTError.defined`；
   - 扩展定义在 namespace 块内嵌套出现；
   - 块体内写非函数声明 → 解析报错。

**Phase 2**
1. parser 对 `extension class` 块体按 class 体解析（函数归类为方法），
   运行时支持 `HTClass` 目标并校验 targetKind 一致。
2. 测试：扩展后新/旧实例均可调用；`this` 正确绑定；不能覆盖已有方法；
   继承链上子类实例是否可见扩展方法（按 class 命名空间查找规则预期可见，测试确认）。

**Phase 3**
1. 先调查 `HTStruct.clone()` 与 `HTNamedStruct.createObject` 的字段拷贝/原型链接语义，
   再定决策点 C。
2. 实现 + 测试。

**收尾**：更新文档 `docs/docs/en-US/grammar/`（新增 extension 页面或并入 namespace 页面）
及对应中文文档；检查 `TODO.md`；按需更新 `AGENTS.md` 的语法说明。

## 5. 决策点汇总

| # | 问题 | 结论/建议 | 状态 |
|---|---|---|---|
| A | extension 块内函数的 category 如何确定 | 已解决：声明中显式写种类（`extension class/namespace/struct`），parser 按种类选择 ParseStyle | ✅ 已确认 |
| B | 是否允许 get/set | 第一版仅普通方法 | 待确认 |
| C | named struct 扩展对已创建对象是否生效 | Phase 3 调查 clone 语义后定 | 延后 |
| D | 语法形态 | `extension <kind> <Id> { ... }`，无 `on` | ✅ 已确认 |

## 6. Phase 1 实现记录（已完成）

改动文件：

- `lexicon/lexicon.dart`、`lexicon/lexicon_hetu.dart`：`kExtension = 'extension'`（上下文关键字，
  与 `namespace` 一样不加入保留字集，不影响把 `extension` 当标识符用的旧脚本）。
- `common/internal_identifier.dart`：`extensionDeclaration`。
- `ast/ast.dart`：`ExtensionTargetKind` 枚举 + `ExtensionDecl` 节点；
  8 个 visitor 站点（abstract/recursive visitor、analyzer、analyzer_impl、type_checker、
  constant_interpreter、compiler、formatter）各自添加 `visitExtensionDecl`。
- `parser/parser_hetu.dart`：`_parseExtensionDecl`（只接受 `extension namespace`，
  其他种类报语法错误）；在 script/module/explicitNamespace/functionDefinition
  四种 ParseStyle 下分发；解析后校验块内语句全部为 `FuncDecl`，否则记录语法错误；
  块内函数的 `explicityNamespaceId` 设为目标 id（获得 `Ns::name` 显示名与外部函数绑定约定）。
- `bytecode/op_code.dart`：`extensionDecl = 45` / `extensionDeclEnd = 46`
  （填补 44–49 空档，无重编号）；`HTExtensionTargetKindCode` 字节码常量。
- `bytecode/compiler.dart`：`visitExtensionDecl`（载荷：targetKind 一字节 + targetId）。
- `interpreter/interpreter.dart`：
  - `OpCode.extensionDecl`：在 `currentNamespace` 沿 closure 链递归查找目标
    （`memberGet(..., asDeclaration: true)`，覆盖 symbols + importedSymbols），
    未找到 → `HTError.undefined`；不是 namespace → `HTError.notNamespace`（新增错误码
    + 中英文 locale）。命中后把目标压为 currentNamespace，块内函数经现有 funcDecl 流程
    直接 define 进目标符号表，重名冲突由 `define()` 现有检查抛 `HTError.defined`。
  - **模块内扩展的 import 时机问题**：.ht 模块的 import 延迟到 endOfModule 才解析，
    模块文件中的 extension 会执行得太早看不到 import 符号。解法：目标查找失败且
    当前命名空间有未决 import 时，对已在 `_currentBytecodeModule.namespaces`
    注册的来源（bundler 保证依赖先于使用者执行）提前解析，并从 `imports` 移除避免
    endOfModule 重复处理。
  - `_extensionContextStack` 保存/恢复定义现场（目标 namespace 的 closure 不是
    定义处，不能用 namespaceDeclEnd 的 closure 弹栈方式）；`loadBytecode` 入口清空，
    防止扩展块内报错后状态污染后续 eval。
- `formatter/formatter.dart`：`visitExtensionDecl`。
- 新增错误码 `HTErrorCode.notNamespace` + `HTError.notNamespace` + 中英文 locale。

测试：`test/interpreter/extension_test.dart` 7 例（入口脚本扩展、模块内扩展、
共享对象原地可见性、成员冲突报错、目标未定义报错、目标非 namespace 报错、
非函数成员拒绝）。`dart test` 全量 430 例通过；
`precompiled_module.dart` 已用 `dart run utils/compile_hetu.dart` 重新生成。

已知语义（有意为之，已写入文档）：

- 扩展方法的闭包是**目标命名空间**而非定义处文件——方法体内按目标 namespace 的
  符号链解析名字，看不到定义文件的私有符号。
- 跨 eval 重新 import 同一文件会重新执行并创建新的命名空间对象，原地扩展不跨模块
  加载保留（与现有模块缓存语义一致）。
