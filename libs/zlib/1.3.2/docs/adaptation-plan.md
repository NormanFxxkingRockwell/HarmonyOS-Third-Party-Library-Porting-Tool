# zlib 适配方案

## 1. 项目结构概览

- 核心源码位于 `libs/zlib/` 根目录，主要包含 `adler32.c`、`compress.c`、`crc32.c`、`deflate.c`、`inflate.c`、`gz*.c`、`zutil.c` 等。
- 公开头文件主要为 `libs/zlib/zlib.h` 和 `libs/zlib/zconf.h`。
- 构建入口同时存在 `libs/zlib/CMakeLists.txt` 和 `libs/zlib/configure`，其中 CMake 为更直接的主入口。
- 上游测试/示例入口已存在：
  - `libs/zlib/test/example.c`
  - `libs/zlib/test/minigzip.c`
  - `libs/zlib/test/infcover.c`
  - `libs/zlib/examples/zpipe.c`

## 2. 平台相关代码识别

- 主库代码平台相关性较低，主要依赖标准 C 运行时和常见 POSIX 头文件。
- `CMakeLists.txt` 会检查 `unistd.h`、`fseeko`、`off64_t` 等能力，这些在 HarmonyOS NDK 路径下通常可用。
- 仓库内存在明显的 Windows 专用实现和说明，但集中在 `win32/`、`contrib/zlib1-dll/`、`contrib/minizip/iowin32.*` 等非主库路径。
- `test/minigzip.c` 和部分 `examples/` 使用 `unistd.h`、`mmap` 等接口，属于测试程序层面的平台差异，不构成主库移植阻塞。

## 3. HarmonyOS 业务适配点

- 当前未发现主库源码必须替换为 HarmonyOS 专有接口的业务适配点。
- 当前未发现必须新增 `OHOS` 平台宏分支才能编译主库的证据。
- 当前建议不在 Phase 4 对 `libs/zlib/` 业务代码做任何修改，优先保持上游源码不变。
- 若 Phase 5 在测试程序编译阶段暴露平台差异，应将其归类为构建驱动或测试入口问题，而不是业务代码适配问题。

## 4. 可复用测试入口与指导

- 优先复用上游测试程序：
  - `test/example.c`
  - `test/minigzip.c`
- 推荐优先使用 CMake 已定义的测试目标进行构建，必要时从构建目录回收 `zlib_example` 或 `minigzip` 到 `outputs/zlib/bin/`。
- 若上游测试程序在 HarmonyOS 侧运行受限，可退化为最小驱动，只验证 `compress()` / `uncompress()` 或 `deflate()` / `inflate()` 调用链。
- 当前允许在没有可直接复用 binary 的情况下生成 minimal test driver。

## 5. 给 Phase 5 的最小交接摘要

- 构建系统类型：`cmake`
- 现成 `HPKBUILD`：已发现
  - `tpc_c_cplusplus/thirdparty/zlib/HPKBUILD`
  - `tpc_c_cplusplus/community/zlib/HPKBUILD`
- 优先建议：先尝试 `lycium`
- fallback 预期：低，但若 recipe 与目标版本不一致，需要先选用或修正合适 recipe
- 已知风险：
  - `community/zlib/HPKBUILD` 仍指向 `v1.2.13`，不匹配任务表中的 `1.3.2`
  - `thirdparty/zlib/HPKBUILD` 已升级到 `1.3.2`，更适合作为本轮 `lycium` 起点
  - 测试程序可能涉及 `mmap` 或运行环境差异，设备侧验证时应优先选择更简单的示例程序
