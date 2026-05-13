# bzip2 适配方案

## 1. 项目结构概览

- 核心源码位于 `libs/bzip2/` 根目录，主要包括 `blocksort.c`、`huffman.c`、`compress.c`、`decompress.c`、`bzlib.c`。
- 公开头文件为 `libs/bzip2/bzlib.h`。
- 默认构建入口为 `libs/bzip2/Makefile`。
- 仓库还提供共享库构建入口 `libs/bzip2/Makefile-libbz2_so`。
- 上游可复用 CLI/测试入口：
  - `bzip2`
  - `bzip2recover`
  - `bzip2-shared`（由 `Makefile-libbz2_so` 生成）

## 2. 平台相关代码识别

- 主库代码平台相关性较低，核心算法实现基本是纯 C。
- 平台差异主要集中在 CLI 程序 `bzip2.c` 对 `unistd.h` 的使用。
- 当前未发现线程、网络、动态加载等 HarmonyOS 特殊适配点。
- 当前未发现必须引入 `OHOS` 宏分支才能通过主库编译的证据。

## 3. HarmonyOS 业务适配点

- 当前未发现主库层面的业务代码适配需求。
- 当前建议不修改 `libs/bzip2/` 业务源码，优先保持上游实现不变。
- 本库更可能出现的问题是构建路径问题，而不是业务逻辑问题：
  - 默认 `Makefile` 只产出 `libbz2.a`
  - 项目要求必须交付 `.so`
  - 现成 `lycium` recipe 版本与任务版本不一致

## 4. 可复用测试入口与指导

- 可优先复用的上游 binary：
  - `bzip2`
  - `bzip2-shared`
- 推荐设备侧优先使用 CLI 做最小验证：
  - 查看帮助
  - 对样例文本做压缩和解压
- 若 `bzip2-shared` 可成功生成，则优先使用该 binary 做共享库链路验证。
- 当前不需要额外生成 minimal test driver，除非上游 CLI 无法在 HarmonyOS 侧运行。

## 5. 给 Phase 5 的最小交接摘要

- 构建系统类型：`make`
- 现成 `HPKBUILD`：已发现 `tpc_c_cplusplus/thirdparty/bzip2/HPKBUILD`
- 是否建议优先尝试 `lycium`：建议先做一次验证
- 是否预期需要 fallback：高概率需要
- 已知高风险：
  - 现成 recipe 版本为 `1.0.6`，与任务表 `1.0.8` 不一致
  - 现成 recipe 的 `build()` 只构建 `libbz2.a bzip2 bzip2recover`
  - 现成 recipe 的 `package()` 不会产出 `.so`
  - 上游已提供 `Makefile-libbz2_so`，fallback 成本较低
