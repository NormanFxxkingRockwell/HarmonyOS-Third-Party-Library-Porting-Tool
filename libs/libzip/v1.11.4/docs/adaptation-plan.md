# libzip 适配方案

## 1. 项目结构概览

- 核心库源码位于 `libs/libzip/lib/`，公开头文件主要为 `zip.h`。
- 官方主构建入口是顶层 `CMakeLists.txt`，属于明确的 `cmake` 项目。
- 上游 CLI 与工具程序位于 `libs/libzip/src/`，主要包括：
  - `ziptool`
  - `zipcmp`
  - `zipmerge`
- 示例程序位于 `libs/libzip/examples/`，包括：
  - `add-compressed-data`
  - `autoclose-archive`
  - `in-memory`
- 回归测试位于 `libs/libzip/regress/`，包含：
  - 大量 `.test` 脚本
  - 辅助测试程序
  - 大量 zip 测试样本数据

## 2. 平台相关代码识别

- 项目存在 Windows 条件分支，典型位置包括：
  - `libs/libzip/lib/compat.h`
  - `libs/libzip/lib/zip.h`
  - `libs/libzip/lib/zip_source_file_stdio.c`
  - `libs/libzip/lib/zip_source_file_win32.h`
  - `libs/libzip/src/ziptool.c`
- 主库整体仍以标准 C 和常规 POSIX 文件能力为主，没有发现 HarmonyOS 专有系统服务接口依赖。
- `libzip` 构建时会探测并按能力启用以下依赖：
  - `OpenSSL`
  - `bzip2`
  - `xz/liblzma`
  - `zstd`
  - 可选 `GnuTLS`
- `regress/` 中存在 `execv`、测试脚本、测试数据目录和 `nihtest` 依赖，说明完整回归套件更偏宿主机/CI 使用，不是天然适合设备侧直接复用的入口。
- `ziptool`、`zipcmp`、`zipmerge` 是独立可执行程序，且直接基于主库 API 提供文件级真实操作，更适合作为设备侧候选入口。

## 3. HarmonyOS 业务适配点

- 当前未发现 `libs/libzip/lib/` 主库逻辑必须替换为 HarmonyOS 专有业务接口的证据，优先保持上游主库源码不变。
- 当前更可能出现的问题集中在：
  - 交叉编译时依赖探测
  - crypto / compression feature 开关
  - recipe 中旧 patch、旧版本和旧包名的不一致
- 优先沿用上游现有 Unix-like / POSIX 路径，不主动新增 HarmonyOS 专有宏分支；只有编译错误明确要求时，才做最小修改。
- 依据 `docs/06-code-analysis.md` 的“优先让流程走通”规则，Phase 4 不预设业务源码改动，优先让 `.so` 与上游 CLI 打通。

## 4. 可复用测试入口与指导

- 当前库存在上游自带、可独立运行的候选入口，但需要区分优先级。
- 不优先作为设备侧首选的入口：
  - `libs/libzip/regress/`
  - 原因：它依赖 `Python + nihtest`、大量 `.test` 脚本、样本数据和宿主测试环境，不是当前库最合适的设备侧独立运行入口。
- 优先候选入口：
  - `libs/libzip/src/ziptool`
  - `libs/libzip/src/zipcmp`
  - `libs/libzip/src/zipmerge`
- 其中更适合设备侧真实能力验证的是 `ziptool`，因为它支持直接对 zip 包做创建、添加、读取等真实操作，适合覆盖“写入 -> 读取 -> 内容比对”路径。
- 推荐设备侧真实功能验证路径：
  - 用 `ziptool` 创建 zip 包并加入测试文件
  - 再用 `ziptool` 读取归档中的对应条目
  - 对原始文本与读出的内容做比对
- `zipcmp` 可作为补充校验入口，但首选仍建议 `ziptool`，因为它同时覆盖写和读路径。
- 当前库不是“无测试用例”：
  - 有上游 CLI
  - 也有完整回归套件
  但设备侧首选应记录为“上游 CLI 真实功能验证”。

## 5. 给 Phase 5 的最小交接摘要

- 构建系统类型：`cmake`
- 是否发现现成 `HPKBUILD`：是。
  - `tpc_c_cplusplus/thirdparty/libzip/HPKBUILD`
- 是否更适合优先尝试 `lycium`：是。
  - 依据：已存在同库现成 recipe，符合 `docs/README.md` 的 lycium-first 规则。
- 是否预计需要 fallback：暂不预设，先严格执行 recipe 预检查与预修正，再做 lycium 实际构建。
- 已知高风险依赖或构建障碍：
  - 现成 recipe 版本仍是 `v1.9.2`，而任务表目标版本是 `v1.11.4`，必须先做 recipe 升级。
  - `SHA512SUM`、`packagename`、`builddir` 当前都围绕 `1.9.2`，必须同步修正，不能因为版本不一致直接 fallback。
  - 现成 patch `libzip_oh_pkg.patch` 只覆盖旧版本顶层 `CMakeLists.txt` 的 rpath 逻辑，需要验证对 `v1.11.4` 是否仍适用。
  - recipe 当前没有明确 binary 回收说明；Phase 5 需要优先确保 `ziptool` / `zipcmp` / `zipmerge` 这类上游 CLI 能被安装或回收。
