# curl 业务代码适配方案

## 1. 项目结构概览

- 核心源码目录：`lib/` (126 个 .c 文件，129 个 .h 文件)
- 公开头文件目录：`include/curl/` (curl.h, easy.h, multi.h 等)
- CLI 工具目录：`src/` (curl 命令行工具源码)
- 测试目录：`tests/unit/` (单元测试), `tests/libtest/` (库测试)
- 构建配置：`CMakeLists.txt` (主构建文件，约 91KB)

## 2. 平台相关代码识别

- 平台宏：`_WIN32`, `__linux__`, `HAVE_LINUX_TCP_H`
- 系统调用：socket、connect、bind、listen 等网络 API
- 平台判断：CMake 使用 `CMAKE_SYSTEM_NAME` 判断平台类型
- 关键文件：`lib/cf-socket.c`, `lib/connect.c` 等涉及网络底层

## 3. HarmonyOS 业务适配点

- CMake 需要识别 OHOS 系统类型（在 `lib/CMakeLists.txt` 中）
- 网络相关系统调用在 HarmonyOS 上兼容 Linux API
- 需要配置 CA 证书路径：`/etc/ssl/certs/cacert.pem`

## 4. 建议修改清单

- 应用 `curl_oh_pkg.patch`：让 CMake 的 `CMAKE_SYSTEM_NAME` 识别 "OHOS"
- 该 patch 已存在于 lycium 的 curl recipe 中，可直接复用

## 5. 风险与假设

- 依赖库风险：需要 openssl, zstd, nghttp2 先编译成功
- 版本升级风险：从 curl-8_9_1 升级到 curl-8_19_0，patch 可能需要微调
- 假设：HarmonyOS 网络 API 与 Linux 兼容

## 6. 可复用测试入口与指导

- 上游 test program：`tests/unit/` 目录下的单元测试 (unit1300.c 等)
- 若无合适 test program，上游 CLI：`curl` 命令行工具 (位于 src/)
- 优先推荐的运行命令：
  - 单元测试：构建后执行 `tests/unit/curl-unit-tests`
  - CLI 验证：`curl --version` 和 `curl -o output.html https://www.baidu.com`
- 若无现成入口，是否无测试用例：有现成测试入口和 CLI

## 7. 给 Phase 5 的最小交接摘要

- 构建系统类型：CMake
- 是否发现现成 `HPKBUILD`：是，`tpc_c_cplusplus/community/curl_8_9_1/HPKBUILD`
- 是否更适合优先尝试 `lycium`：是，已有现成 recipe 可升级
- 是否预计需要 fallback：否，lycium 路径优先
- 已知高风险依赖或构建障碍：
  - 依赖 openssl, zstd, nghttp2
  - 需要验证 curl_oh_pkg.patch 对 curl-8_19_0 版本的兼容性