# JavaScript 风格 API 别名兼容计划

## 文档说明

目标：让有 JavaScript/TypeScript 背景的开发者可以凭已有习惯使用 Hetu 标准库，同时保持与 Dart 宿主的零成本互操作。

核心原则：

- **Dart 语义为唯一事实来源**。别名只是同一 Dart 实现的另一个名字，行为（返回值、异常、惰性求值、参数规则）一律以 Dart SDK 为准。行为文档直接引用 Dart，不维护第二套语义。
- **只提供 Dart 已有的 API 和功能**。不引入 Dart 没有的新功能；个别尚未暴露到脚本的 Dart 已有方法（如 `forEach`）属于"补充暴露"，需单独列出并经确认后实施。
- **只加不改**。不删除、不重命名现有 API，不改变现有 API 的行为。已存在的 JS 同名但语义不同的 API（见"已知偏差"）保持行为不变，以文档标注差异的方式处理。
- **不引入 JavaScript 的语义怪癖**：隐式类型转换、宽松相等、`this` 绑定规则、原型链细节、负索引下标等均不在兼容范围内。兼容止步于"常用 API 词汇表"。

状态：阶段一与阶段三（P1 候选）已完成并通过验收；阶段二文档待执行。每个阶段独立完成、独立验收。

## 技术路径（已调研确认）

别名的实现按对象类型分三条路径，均不触碰解释器内核：

1. **external class（`number/string/List/Map/Set/Future` 等）**：在 `packages/hetu_script/lib/binding/class_binding.dart` 对应类的 `instanceMemberGet` 的 `switch (id)` 中新增 `case`，复用与原方法完全相同的实现闭包；同时在 `lib/*.ht` 的 external class 声明中补充方法签名，保持声明与绑定一致（供 analyzer、`help()` 和文档使用）。
2. **struct `Object`（prototype 对象）**：直接在 `lib/object.ht` 中用 Hetu 代码包装现有方法，沿用 `hasOwnProperty()` 包装 `containsKey()` 的已有模式，不需要改 Dart 代码。
3. **类型与常量别名**：类型沿用 `type Promise = Future` 的先例；常量（如 `Math.PI`）在 `lib/math.ht` 中以 `static const` 声明同名值。

每次修改 `lib/*.ht` 后必须运行 `dart run utils/compile_hetu.dart` 重新生成 `packages/hetu_script/lib/precompiled_module.dart`，并一并提交。

## 阶段一：核心集合与字符串别名

### 执行记录

阶段一已完成：候选清单中全部 P0 别名已实现，并有以下范围调整：

- `Math.min/max` 按讨论决定扩展为 variadic（`... values: number`）：两个值时退化为单次 `dart:math` 比较，多值时循环折叠比较；null 值忽略（保留原有双参 null 语义），空参数按 JS 返回 `Infinity`/`-Infinity`，NaN 正常传播。参数数量通过绑定层 `positionalArgs` 与脚本 variadic 列表获取，无需引入 JS 的 `arguments` 对象。
- `console.warn` 已作为主名实现，`console.warning` 保留别名。
- 类型别名静态成员访问已修复：`_handleTypeAliasDecl` 在别名可解析到 `HTClass` 时直接指向该类（泛型参数、nullable、前向引用等场景回退到原有的纯类型行为），`Promise.resolve/all` 与 `Number.isNaN/isFinite`（`type Number = number`）随之实现。
- `Set.delete` 放弃：`delete` 是 Hetu 一元运算符关键字，不能作为方法名。
- 全局 `NaN/Infinity` 以 `final` 顶层变量实现（`float.nan`/`float.infinity` 为运行时值）。

验收：`test/binding/js_alias_test.dart` 新增 31 项等价性测试（含类型别名静态访问、链式别名、类型注解与前向引用回归）；全量 `dart test` 576 项通过；修改文件 `dart analyze` 无问题；`precompiled_module.dart` 已重新生成。

### 执行记录（阶段三 P1 候选）

- `Iterable.forEach`、`Map.forEach`（回调为 Dart 顺序 `(key, value)`，与 JS 参数顺序的差异已在声明注释中标注）。
- `Map.get/set`（`[]`/`[]=` 的方法形式）、`Map.entries`；同时补充注册此前漏掉的 `HTMapEntryBinding`（绑定类早已存在但未在 `Hetu.init()` 注册，导致 `MapEntry` 构造器在脚本中不可用）。
- `Promise.catch/finally`（兼提供 Dart 原名 `catchError/whenComplete`）、`Promise.reject`（兼 `Future.error`）：经验证 `catch/finally` 可作成员名，声明与点号调用均合法。
- `Map.delete`、`Set.delete` 已实现：`delete` 在 parser 中本就只在语句开头分派（`_parseDeleteStmt`），将其从 `lexicon.keywords` 保留字集合移除后即成为上下文关键字——语句开头仍为 delete 语句，函数名/成员名位置可作标识符，与 `catch/finally/throw` 不在保留字集合中的先例一致。注意：语句开头的 `delete` 永远优先按 delete 语句解析，因此不宜把 `delete` 用作普通变量/函数名后直接以其开头调用。
- `Math.atan2`；`String.charAt/repeat/fromCharCode`（新增 `type String = string` 别名）。
- `Object.entries`（返回 `List<MapEntry>`）、`Object.fromEntries`（支持 `MapEntry` 与二元列表对）。

验收：新增 11 项测试；全量 `dart test` 586 项通过；修改文件 `dart analyze` 无问题；`precompiled_module.dart` 已重新生成。

### 候选范围

范围：`List/Iterable/String/Map/console/Math`。下表为候选清单，"语义说明"列必须同步写入阶段二的兼容矩阵。

### List / Iterable

| JS 别名 | 现有实现 | 语义说明 |
| --- | --- | --- |
| `push(value)` | `add(value)` | 返回 `void`，不返回 JS 的新长度 |
| `pop()` | `removeLast()` | 返回被移除元素，与 JS 一致 |
| `shift()` | `removeFirst()` | 返回被移除元素，与 JS 一致 |
| `unshift(value)` | `insert(0, value)` | 返回 `void`，不返回 JS 的新长度 |
| `filter(test)` | `where(test)` | 返回**惰性 Iterable**，需要数组时接 `.toList()` |
| `some(test)` | `any(test)` | 一致 |
| `includes(value)` | `contains(value)` | 一致 |
| `findIndex(test)` | `indexWhere(test)` | 无匹配返回 `-1`，与 JS 一致 |
| `find(test)` | `firstWhere(test)` | 无匹配时返回 `null`（绑定已提供 `orElse`），接近 JS 的 `undefined` |
| `slice(start, [end])` | `sublist(start, [end])` | 不支持 JS 的负索引 |

### String

| JS 别名 | 现有实现 | 语义说明 |
| --- | --- | --- |
| `padStart(width, [padding])` | `padLeft` | 一致 |
| `padEnd(width, [padding])` | `padRight` | 一致 |
| `trimStart()` | `trimLeft()` | 一致 |
| `trimEnd()` | `trimRight()` | 一致 |
| `charCodeAt(index)` | `codeUnitAt(index)` | 均为 UTF-16 码元，一致 |
| `includes(other, [startIndex])` | `contains` | 一致 |

### Map / console / Math

| JS 别名 | 现有实现 | 语义说明 |
| --- | --- | --- |
| `Map.has(key)` | `containsKey(key)` | 一致 |
| `console.warn(...)` | 主名统一为 `warn` | 已决定：脚本侧 `console.warn` 为主名（与 JS 及 SLF4J/Ruby/Rust/Go 等主流 logger 一致），`console.warning` 保留为别名；Dart 内部 `MessageSeverity.warning` 与级别显示名 `WARNING` 保持不变 |
| `Math.PI` / `Math.E` | `pi` / `e` | 常量别名，值相同 |

明确不做的常见项：`concat`（用 spread 字面量替代）、`Array.isArray`（用 `is List`）、`Object.create` 的 JS 原型语义、`catch` 方法名（与关键字冲突，需单独调研，不在本阶段）。

## 阶段二：兼容矩阵文档与已知偏差标注

在 `docs/docs/` 的英文与中文文档中各新增一页"JavaScript 开发者指南 / API 兼容矩阵"，内容：

1. 阶段一全部别名的对照表及语义说明列。
2. **已知同名偏差清单**（只标注，不改行为）：
   - `float.toFixed()`：Hetu 返回 `float`（`double.parse(toStringAsFixed(...))` 的往返实现），JS 返回 string；需要字符串时用 `toStringAsFixed()`。
   - `Object.create(data)`：Hetu 语义为深拷贝/类型转换，不是 JS 的原型创建。
   - `filter/map` 等返回惰性 `Iterable`，与 JS 返回新数组不同。
   - `JSON.jsonify/deepcopy`、`List.random` 等为 Hetu 扩展，JS 中不存在。
3. 一句话原则声明："别名方法的行为以 Dart SDK 对应方法为准"。

## 阶段三（可选，需求驱动）：补充暴露 Dart 已有方法

仅在真实使用需求出现时逐项评估，每项单独确认：

- `Iterable.forEach`（Dart 已有，当前未暴露到脚本）。
- `Map.entries`（`fromEntries` 构造器已存在，取值侧未暴露）。
- `Future.catchError/whenComplete` 及是否提供 `Promise` 风格别名（`catch` 与关键字冲突，需先验证成员名解析）。

## 测试与验收

1. 在 `test/binding/` 新增别名等价性测试：每个别名至少一项"别名调用与原名调用结果一致"的断言，覆盖正常路径与边界（空列表、无匹配、可选参数省略）。
2. `console.warn`、`Math.PI` 等走各自现有测试入口补充用例。
3. 全量 `dart test` 通过；修改文件 `dart analyze` 无新增问题。
4. `precompiled_module.dart` 已重新生成，且 REPL/示例中可直接使用新别名（用 `script/` 下临时脚本验证，验证后删除）。

## 不做清单（防止范围蔓延）

- 不改变任何现有 API 的行为或返回类型。
- 不实现 JS 的隐式转换、宽松相等、原型继承、负索引。
- 不为对齐 JS 而在 Dart 互操作边界增加包装/转换层。
- 不引入 Dart 没有的功能性 API（如 `setTimeout`、正则字面量等），此类需求另立计划讨论。
