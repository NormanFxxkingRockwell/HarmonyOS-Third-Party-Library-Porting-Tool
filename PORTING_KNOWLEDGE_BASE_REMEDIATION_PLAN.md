# 鸿蒙化三方库知识库整改计划

## 1. 当前问题

本仓库的目标不是简单备份 `ho-thirdparty-porting` 的构建产物，而是沉淀每个三方库的鸿蒙化知识包，方便其他使用者复用：

- 该库在鸿蒙化过程中改了什么
- 为什么要这样改
- 哪些 recipe、patch、cross-file、构建参数可以复用
- 已编译产物在哪里，覆盖哪些架构
- 真实验证入口是什么，验证结果如何
- 换到同库新版本时哪些内容可直接复用，哪些必须重新评估
- 本仓库当前只保留 `arm64-v8a` 产物和配置，不再迁移或声明其他架构

历史上的错误迁移提交 `902ba6a Migrate 41 libraries from ho-thirdparty-porting` 的主要问题是方向偏了：它更像机械迁移快照，而不是可复用的鸿蒙化记录。

已发现的事实：

- `scripts/migrate-library.sh` 会为每个库生成模板化 `modifications.md`，没有提炼真实适配过程。
- `libs/*/*/docs/` 基本为空，没有迁移 `../ho-thirdparty-porting/reports/<库>/` 下已有的 `adaptation-plan.md`、`adaptation-report.md`、`build-report.md`。
- `libs/*/*/patches/` 基本为空，但多个 `HPKBUILD` 实际引用了同级 patch 或 cross-file。
- `meta.yaml` 里架构和构建系统存在硬编码，不能代表真实 recipe 和 artifact 状态。
- 部分产物只复制了 `.so*`，丢失了 `outputs/<库>/bin/`、运行时依赖库、符号链接、设备验证入口等复用信息。
- 该错误提交已从 `main` 重做掉，并保存在本地备份分支 `codex/bad-migration-snapshot`，仅供必要时追溯。

结论：不要恢复或继续推送 `902ba6a` 的批量迁移结果。

## 2. 正确目标

每个库应形成一个可被人和 AI 复用的知识包：

```text
libs/<库名>/<版本>/
├── meta.yaml
├── modifications.md
├── artifacts/
│   ├── lib/
│   ├── bin/
│   └── arm64-v8a/           # 当前只保留 arm64-v8a
├── recipe/
│   ├── HPKBUILD
│   ├── SHA512SUM
│   ├── *.patch
│   └── *cross-file*
├── patches/
│   └── 源码级补丁或从 recipe 依赖中归档的 patch
└── docs/
    ├── adaptation-plan.md
    ├── adaptation-report.md
    └── build-report.md
```

目录不必机械完全一致，但必须满足两个要求：

- 用户可以直接找到产物和使用入口。
- 后续 AI 可以只读当前仓库，理解该库鸿蒙化过程并套用到同库新版本。

## 3. 总体策略

先纠正结构和规则，再批量回填数据。

不要先迁移剩余 11 个库。当前更重要的是防止错误模型继续扩大。

推荐顺序：

1. 以 `libzip` 做样板库。
2. 修正迁移脚本和校验脚本。
3. 用新规则回填已迁移库。
4. 再处理剩余未迁移库。
5. 最后决定是否替换、修正或追加提交。

## 4. 阶段计划

### 阶段 0：冻结错误扩散

目标：

- 暂停 `git push origin main`。
- 不继续基于旧 `scripts/migrate-library.sh` 迁移剩余库。
- 保留现场，先做只读分析和计划落地。

交付物：

- 本计划文档。
- 当前问题清单。

验收标准：

- 后续 AI 明确知道不能恢复或继续推送 `902ba6a` 的批量迁移结果。
- 后续 AI 明确知道剩余 11 个库不是当前第一优先级。

### 阶段 1：用 libzip 建立正确样板

目标：

- 将 `libs/libzip/v1.11.4/` 修成一个完整知识包。

数据来源：

- `../ho-thirdparty-porting/reports/libzip/adaptation-plan.md`
- `../ho-thirdparty-porting/reports/libzip/adaptation-report.md`
- `../ho-thirdparty-porting/reports/libzip/build-report.md`
- `../ho-thirdparty-porting/tpc_c_cplusplus/thirdparty/libzip/HPKBUILD`
- `../ho-thirdparty-porting/tpc_c_cplusplus/thirdparty/libzip/SHA512SUM`
- `../ho-thirdparty-porting/tpc_c_cplusplus/thirdparty/libzip/libzip_oh_pkg.patch`
- `../ho-thirdparty-porting/outputs/libzip/`
- `../ho-thirdparty-porting/tpc_c_cplusplus/lycium/usr/libzip/`

需要修正：

- `modifications.md`：改成真实说明，包含 recipe 从旧版本升级、依赖开关、patch 适配、失败分类、设备验证路径。
- `docs/`：迁移 libzip 的三份报告。
- `recipe/` 或 `patches/`：补齐 `libzip_oh_pkg.patch`，保证 `HPKBUILD` 引用文件在当前知识包中可找到。
- `artifacts/`：保留 `libzip.so*`、`ziptool`、`zipcmp`、`zipmerge`、运行时依赖库和必要符号链接关系。
- `meta.yaml`：只记录 `arm64-v8a` 和真实验证状态，不声明其他架构。

验收标准：

- 只读 `libs/libzip/v1.11.4/` 就能回答：libzip 改了什么、为什么改、如何构建、如何验证、产物有哪些。
- `HPKBUILD` 引用的 patch 文件在本目录结构中存在。
- `meta.yaml` 与 recipe/artifacts 一致。
- 文档中包含设备侧真实功能验证命令或结果摘要。

### 阶段 2：修正迁移脚本

目标：

- 将 `scripts/migrate-library.sh` 从“机械复制脚本”改成“知识包生成脚本”。

脚本必须做到：

- 从 recipe 解析真实 `pkgver`、`archs`、`buildtools`。
- 支持 outputs 名与 recipe 名不一致的显式映射表，例如：
  - `Abseil` -> `abseil-cpp`
  - `Expat` -> `libexpat`
  - `FreeType` -> `freetype2`
  - `GNU_libiconv` -> `libiconv`
  - `GNU_libunistring` -> `libunistring`
  - `LZ4` -> `lz4`
  - `LZMA_SDK` -> `xz`
  - `Mbed_TLS` -> `mbedtls`
  - `Protocol_Buffers` -> `protobuf`
  - `Zstandard` -> `zstd`
- 复制 `../ho-thirdparty-porting/reports/<库>/` 到 `docs/`。
- 扫描 `HPKBUILD` 引用的 `.patch`、`*cross-file*`、额外资源，并复制到 `recipe/` 或 `patches/`。
- 复制 `outputs/<库>/` 的 `lib/`、`bin/`、运行时依赖库和符号链接。
- 复制 `lycium/usr/<pkg>/arm64-v8a/` 的 include/lib/bin 产物；不要迁移或声明其他架构。
- 生成 `meta.yaml` 时标注事实来源和不确定项。
- 生成 `modifications.md` 时只能生成结构化草稿，不能假装已经完成真实总结。

验收标准：

- 新脚本不会生成空洞模板 `modifications.md`。
- 新脚本不会硬编码多架构，当前只输出 `arm64-v8a`。
- 新脚本不会丢失 recipe 引用的 patch/cross-file。
- 对找不到映射或找不到报告的库，脚本应失败或明确标记 `needs-manual-review`，不能静默生成看似完整的数据。

### 阶段 3：新增校验脚本

目标：

- 给后续批量回填提供自动质量门禁。

建议新增 `scripts/validate-library-package.sh`，检查单个库目录：

- `meta.yaml` 是否存在。
- `modifications.md` 是否仍是模板。
- `docs/build-report.md` 是否存在。
- `recipe/HPKBUILD` 引用的 patch/cross-file 是否存在。
- `meta.yaml` archs 是否与 recipe `archs=(...)`、artifacts 目录一致。
- artifacts 是否为空。
- 如果 `docs/build-report.md` 记录了 CLI 或设备验证入口，artifacts 是否包含对应 `bin/`。
- 如果 artifact 中有 `.so` 符号链接，迁移后是否保留链接或明确记录如何恢复。

验收标准：

- 可以对 `libs/libzip/v1.11.4` 跑通。
- 可以对按旧脚本迁移出来的库输出问题清单。
- 校验只读，不修改库内容。

### 阶段 4：回填已迁移库

目标：

- 用新规则重新回填旧迁移提交中曾经批量生成的库。

执行方式：

- 一次处理一个库。
- 可以使用 subAgent 做只读分析和报告提炼，但写入必须串行。
- 优先处理 `HPKBUILD` 引用 patch/cross-file 的库，例如：
  - `libzip`
  - `libuv`
  - `OpenCV`
  - `OpenSSL`
  - `SQLite`
  - `curl`
  - `Pixman`
  - `GLib`
  - `HarfBuzz`
- 每个库处理后运行校验脚本。

每个库的交付物：

- 真实 `modifications.md`
- `docs/` 下真实报告
- 补齐 recipe 依赖文件
- 修正 `meta.yaml`
- 修正 artifacts 覆盖范围和说明

验收标准：

- 重新回填后的库不再依赖空模板说明。
- 每个库都能说明可复用内容与风险。

### 阶段 5：迁移剩余库

待已迁移库规则稳定后，再处理剩余 11 个库：

- `Abseil`
- `Expat`
- `FreeType`
- `GNU_libiconv`
- `GNU_libunistring`
- `LZ4`
- `LZMA_SDK`
- `Mbed_TLS`
- `Protocol_Buffers`
- `Zstandard`
- `parson`

注意：

- 不要只因为 recipe 名和 outputs 名不一致就跳过。
- 先按映射表查 recipe。
- 如果 recipe 存在于 `community/`，要在 metadata 中记录真实来源。
- 如果报告存在于 `reports/<库>/`，必须迁移。
- 如果缺 report 或 recipe 归属不确定，标记人工复核，不要伪造完整知识包。

验收标准：

- 11 个库按同一标准完成。
- 映射关系进入脚本或文档，不靠口头交接。

### 阶段 6：Git 处理

错误迁移提交 `902ba6a` 已从 `main` 移除，并保存在本地备份分支 `codex/bad-migration-snapshot`。

可选方案：

- 方案 A：如确实需要追溯旧迁移，可从 `codex/bad-migration-snapshot` 读取，不要合并回 `main`。
- 方案 B：在 `main` 上保持干净历史，只提交整改计划、样板库、校验脚本和后续逐库回填结果。

推荐：

- 优先采用方案 B。
- 如果已有其他 AI 或人需要参考旧结果，只读查看 `codex/bad-migration-snapshot`，不要基于它继续写入。

无论选择哪种方案，推送前必须完成：

- `git status`
- `git diff --stat`
- 针对样板库和批量库的校验结果
- 自查是否还存在模板 `modifications.md`
- 自查是否还存在 `HPKBUILD` 引用文件缺失

## 5. 后续 AI 工作约束

- 不要直接运行旧脚本批量迁移剩余库。
- 不要恢复、合并或推送 `codex/bad-migration-snapshot`。
- 不要为了“完成数量”生成看起来完整但没有来源依据的文档。
- 不要把 `reports/<库>/build-report.md` 的验证结果丢掉。
- 不要把设备验证简化成 `--help` 或版本输出。
- 不要并行写多个库目录；只读分析可以并行，写入必须按库串行。
- 发现新问题时，先判断是否属于当前整改目标；不属于则记录为后续项。

## 6. 推荐下一步

下一步只做一件事：

修正 `libs/libzip/v1.11.4/` 为样板知识包，并补一个只读校验脚本验证它。

只有 libzip 样板通过后，才继续修迁移脚本和批量回填其他库。
