# 计划：Import 解析时机重构 —— Hoist 到文件执行开头（方案 B）

> 状态：**已实现完成**（见文末实现记录）。
> 背景：extension 功能（见 `plan_extension.md` 第 6 节）暴露了 import 延迟解析的
> 结构性问题。本文档是独立的修复计划，采用分析中推荐的方案 B。

## 1. 问题回顾

现状（`packages/hetu_script/lib/interpreter/interpreter.dart`）：

- **脚本路径**（.hts / eval 字面量）：import 语句执行到就立即解析
  （`_handleImportExport` :2296），并递归解析被导入命名空间的 imports（:904-909）。
- **模块路径**（.ht）：只登记 `declareImport`（:2294），延迟到 `endOfModule`
  （:1326-1334）统一解析。

延迟成立依赖三个前提：bundler 后序插入保证依赖先执行（`bundler.dart:86-87,121`）；
模块顶层无即时代码（变量惰性初始化、函数体调用期执行）；脚本模式跳过
endOfModule 由脚本路径递归兜底。

由此产生的问题：

- **P1**：模块命名空间从 `OpCode.file` 到 `endOfModule` 之间是半成品
  （importedSymbols 为空），任何模块执行期需要 import 符号的特性都会撞上
  （extension 是首例）。
- **P2**：extension 里的提前解析是点状补丁（仅目标查找失败时触发、mutate
  imports 表），需要在本重构中移除。
- **P3**：双路径语义不一致；脚本路径的递归依赖 `_currentFileResourceType`
  （当前执行文件的类型而非被处理命名空间所属文件的类型），是脆弱的隐式不变量。
- **P4**：循环导入下 extension 失败。
- **P5**：`warmUpNamespaces()`（:953）全库无调用，死代码。

## 2. 目标与非目标

**目标**：模块命名空间在其任何语句执行之前就是完整的；脚本与模块的 import
解析路径合一；删除 extension 的补丁逻辑。

**非目标**：不做编译期符号表静态化（方案 C，长期方向）；不改动 analyzer
（其 `handleImport` 为空属既有缺口）；不改变 import/export 的语法。

## 3. 设计

### 3.1 编译器：hoist import 字节码

`compiler.dart` 的 `visitSource`（:371-386）目前按 AST 语句顺序发射。
改为：先发射该文件的全部 `ImportExportDecl`（保持相对顺序），再发射其余语句。
import 语句在源码中的位置不再影响语义（位置不敏感，贴近 JS/Python 的提升语义）。

注意：`export { a, b }`（无 fromPath 的纯导出声明，:2315-2326 分支）只操作
`currentNamespace.exports`，顺序无关，可随 import 一起 hoist，也可留在原位——
实现时选简单者（统一 hoist 所有 ImportExportDecl 节点即可，该分支与位置无关）。

### 3.2 解释器：统一为立即解析 + pending 守卫

- 删除 `_handleImportExport` 中按文件类型分叉的 deferral（:2293-2297）：
  `.ht` 与 `.hts` 统一走 `_handleNamespaceImport`。
- `_handleNamespaceImport` 增加守卫：若
  `_currentBytecodeModule.namespaces` 尚未注册 `importDecl.fromPath`
  （循环导入被 bundler 截断的边），则保留在 `nsp.imports` 中待 endOfModule
  处理，不报错。已注册来源的 import 在解析后**从 `imports` 移除**
  （declareImport 与移除成对，endOfModule 不会重复处理）。
- `endOfModule`（:1326-1334）保留，作为 pending 残留的最终 flush——
  此时所有文件都已执行注册，循环导入的截断边在此解析。
- 重新评估 `_handleNamespaceImport` 的脚本递归（:904-909）：hoist 后被导入
  文件的 imports 在其文件开头已解析，递归理论上不再必要；保守做法是保留递归
  但加 visited 防护，或确认传递覆盖后删除并删除 `_currentFileResourceType`
  依赖（P3）。实现时验证后定夺。
- 删除 extension `OpCode.extensionDecl` 中的提前解析补丁（P2），
  extension 目标查找回到单次 memberGet。

### 3.3 语义变化（需在文档与测试中明确）

1. **import 位置不敏感**：脚本中写在 import 语句之前的代码也能看到导入符号。
2. **循环导入**：先执行文件指向后执行文件的 import 边延迟到 endOfModule
   （与现状等价）；该文件执行期内访问对方符号会 undefined——**这本来就是
   现状的行为**（半成品期间访问同样失败），不构成回归。
3. showList 校验（:922 的 undefined 报错）时机提前到文件开头：被导入文件
   此时已完整执行，符号表完整，行为等价。

## 4. 实施步骤

1. `compiler.dart` `visitSource`：分离 import/export 声明优先发射。
2. `interpreter.dart`：
   - `_handleImportExport` 删 deferral 分支，统一立即解析；
   - `_handleNamespaceImport` 加 pending 守卫 + 已解析移除；
   - 处理/验证脚本递归分支（:904-909）；
   - 删除 extensionDecl 的补丁代码；
   - `endOfModule` 保持 flush 语义。
3. 处理 P5：`warmUpNamespaces()` 接入 `endOfModule`（import 完整后预热惰性
   变量，正是它的注释所描述的场景）或删除——实现时确认无外部调用后决定，
   倾向接入（模块加载后预热可提前暴露初始化错误）。
4. 字节码格式不变（只是发射顺序变化），**无需升版本**；但
   `precompiled_module.dart` 需用 `dart run utils/compile_hetu.dart` 重新生成
   （标准库 .ht 的 import 发射顺序随之变化）。
5. 测试：
   - 全量 `dart test` 回归（重点：`test/interpreter/namespace_test.dart` 的
     跨模块用例、`test/file_system/`、extension 全部 7 例——验证补丁删除后
     模块内扩展仍然工作）；
   - 新增：脚本中 import 语句写在引用之后的用例（位置不敏感）；
   - 新增：循环导入用例（a⇄b，验证 endOfModule flush 后双方可见对方符号，
     函数体跨循环调用正常）；
   - 新增：`export ... from` 在 hoist 后的再导出行为；
   - 新增：模块内 extension（现有 extension_test 第 2、3 例已覆盖，确认通过）。
6. 文档：检查 `docs/docs/**/grammar` 中 import 相关页面是否有"位置/顺序"
   描述需要更新；`plan_extension.md` 第 6 节的"实现坑"段落标注已被本重构解决。

## 5. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 循环导入行为微妙变化 | pending 守卫保持与现状等价的最终解析时机；新增循环导入测试 |
| hoist 改变脚本语句顺序副作用（import 触发被导入文件的顶层代码提前于本文件前置语句——实际上现状已如此，bundler 顺序决定） | 无需缓解，现状一致 |
| `_handleNamespaceImport` 的递归删除引入传递性缺口 | 保守保留递归 + visited 集合，或先用测试证明传递覆盖再删 |
| 预编译标准库字节码与新解释器不匹配 | 步骤 4 重新生成，全量测试验证 |

## 6. 验收标准

- `dart test` 全量通过（含新增用例）；
- extension 7 例在补丁删除后全部通过；
- 循环导入、export from、别名/showList 行为与现状一致或有文档化的改进；
- `dart analyze` 无新增 issue。

## 7. 实现记录（已完成）

改动文件：

- `bytecode/compiler.dart` `visitSource`：先发射全部 `ImportExportDecl`，
  再发射其余语句（保持各自相对顺序）。字节码格式不变，仅发射顺序变化。
- `interpreter/interpreter.dart`：
  - `_handleImportExport`：删除按文件类型的 deferral 分叉，统一为
    "来源已注册则立即 `_handleNamespaceImport`，否则 `declareImport` 挂起"。
  - `_handleNamespaceImport`：删除脚本路径的递归分支（:904-909）
    及对 `_currentFileResourceType` 的依赖（P3 消除）。
  - 新增 `_flushPendingImports()`：把所有可解析（来源已注册）的 pending
    import 解析掉并从 `imports` 移除。**在 `OpCode.endOfFile` 调用**——
    这是实现中发现的关键点：循环导入的截断边属于其他文件，仅靠
    endOfModule flush 会在入口文件顶层语句执行后才解析，导致入口顶层
    跨循环调用失败（相对旧脚本模式的回归）；每个文件注册后立即 flush
    可保证"pending 边在其来源注册后立即可用"。`endOfModule` 保留同名
    flush 作为兜底（对脚本模式也不再跳过）。
  - 删除 extension 的提前解析补丁（P2），extension 目标查找回到单次
    memberGet。
- `warmUpNamespaces()`（P5）：**决定不接入**。它会把模块顶层惰性变量变为
  加载期即时初始化，属于独立的语义变化，超出本重构范围；保持现状（死代码，
  注释已说明用途）。
- 测试：`test/interpreter/namespace_test.dart` 新增 "import hoisting" 组 4 例
  （位置不敏感、循环导入函数跨调用、循环导入变量 flush 后可见、export from
  再导出）。全量 434 例通过，`dart analyze` 无 issue，
  `precompiled_module.dart` 已重新生成。
- 文档：`docs/docs/{en-US,zh-Hans}/grammar/import/readme.md` 补充 hoist 与
  循环导入语义说明。

已知边界（与现状一致，非回归）：import 一个 `.hts` 脚本文件仍然会失败
（脚本文件不注册进模块 namespaces 表）——这是既有缺陷，不在本次范围。
