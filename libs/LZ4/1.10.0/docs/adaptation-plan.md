# LZ4 适配方案

## 1. 项目结构概览

- 核心库源码位于 `libs/LZ4/lib/`，主要包含：
  - `lz4.c`
  - `lz4frame.c`
  - `lz4hc.c`
  - `xxhash.c`
- 公开头文件位于 `libs/LZ4/lib/`，包括 `lz4.h`、`lz4frame.h`、`lz4hc.h`、`lz4file.h`。
- CLI 源码位于 `libs/LZ4/programs/`。
- 上游提供 CMake 构建入口：`libs/LZ4/build/cmake/CMakeLists.txt`。

## 2. 平台相关代码识别

- 主库代码平台相关性较低，核心压缩实现基本是纯 C。
- CLI 程序包含 POSIX 能力探测与 `pthread` 支持逻辑，主要集中在：
  - `programs/platform.h`
  - `programs/util.h`
  - `programs/threadpool.c`
- 当前未发现主库必须新增 HarmonyOS 宏分支的证据。
- 测试目录中存在 `mmap` 与 Linux 特定假设，但这些不构成主库交付阻塞。

## 3. HarmonyOS 业务适配点

- 当前未发现主库层面的业务适配需求。
- 当前建议不修改 `libs/LZ4/lib/` 与 `libs/LZ4/programs/` 源码。
- 风险主要在构建系统接入，而不是业务逻辑：
  - 顶层不是直接可用的项目根 CMake
  - 需要从 `build/cmake/` 入口构建

## 4. 可复用测试入口与指导

- 优先复用上游 CLI：
  - `lz4`
- 推荐设备侧最小验证命令：
  - `lz4 -V`
  - `lz4 -h`
- 若需要进一步验证，可使用小文本文件做压缩/解压。
- 当前无需最小测试驱动。

## 5. 给 Phase 5 的最小交接摘要

- 构建系统类型：`cmake`
- 现成 `HPKBUILD`：未发现
- 是否建议优先尝试 `lycium`：否，直接 fallback 更合适
- 是否预期需要 fallback：是
- 已知高风险：
  - 无现成 recipe
  - 顶层入口与常规单仓库 CMake 布局不同
  - CLI 可能涉及 `pthread`，但通常可由 HarmonyOS toolchain 处理
