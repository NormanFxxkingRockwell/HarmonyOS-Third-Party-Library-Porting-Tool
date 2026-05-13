# curl 业务适配报告

## 1. 输入方案

- 输入方案文件：`reports/curl/adaptation-plan.md`

## 2. 已实施修改

- 无需修改源码
- curl-8_19_0 版本已原生支持 OHOS 系统（见 `lib/CMakeLists.txt:267`）
- 原方案中计划的 `curl_oh_pkg.patch` 对该版本不需要

## 3. 与方案的差异

- 方案预计需要应用 patch，但检查发现 curl-8_19_0 已包含 OHOS 支持
- 这是因为 curl 上游在新版本中已接纳了 HarmonyOS 支持的修改

## 4. 遗留业务适配问题

- 无

## 5. 测试入口与使用建议

- 优先 test program 路径：`tests/unit/` 单元测试程序
- 若无合适 test program，优先 CLI 能力校验路径：`curl` 命令行工具
- 关键 API / 参数 / 样例输入：
  - CLI 验证：`curl --version` 查看版本信息
  - 功能验证：`curl -o output.html https://www.baidu.com` 测试 HTTP GET
- 推荐执行命令：
  - 单元测试：构建产物 `tests/unit/curl-unit-tests`
  - CLI 测试：`./curl --version && ./curl -I https://www.baidu.com`

## 6. 交接给 Phase 5 的说明

- 构建系统：CMake
- 业务适配：无需额外修改，上游已支持 OHOS
- 现有 recipe：`tpc_c_cplusplus/community/curl_8_9_1/HPKBUILD` 可作为基础升级到 8_19_0
- 依赖：openssl, zstd, nghttp2
- 测试策略：优先使用 curl CLI 进行功能验证