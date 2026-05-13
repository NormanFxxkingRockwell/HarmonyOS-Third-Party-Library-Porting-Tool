# cJSON 适配方案

## 1. 项目结构概览

- 核心源文件位于 `libs/cJSON/cJSON.c`，公开头文件位于 `libs/cJSON/cJSON.h`。
- 可选扩展库位于 `libs/cJSON/cJSON_Utils.c` 和 `libs/cJSON/cJSON_Utils.h`。
- 官方主构建入口是顶层 `libs/cJSON/CMakeLists.txt`，同时保留了 `libs/cJSON/Makefile` 作为次要构建入口。
- 上游示例程序位于 `libs/cJSON/test.c`，可独立编译运行，覆盖创建、打印、解析等真实功能路径。
- 上游测试入口位于 `libs/cJSON/tests/`，其中 `parse_examples`、`parse_number`、`parse_string`、`misc_tests`、`readme_examples` 等会被构建为独立可执行文件。

## 2. 平台相关代码识别

- `libs/cJSON/cJSON.h` 主要包含 Windows 导出符号与调用约定宏，如 `__WINDOWS__`、`WIN32`、`_WIN32`，未发现 HarmonyOS 专有分支。
- `libs/cJSON/cJSON.c` 在 `ENABLE_LOCALES` 打开时会包含 `<locale.h>` 并调用 `localeconv()` 处理小数点字符。
- 主库代码依赖标准 C 能力，如 `malloc/free`、`strtod`、`snprintf`、`pow/isnan/isinf`、`memcpy`，未发现线程、网络、进程或复杂文件系统调用。
- `libs/cJSON/CMakeLists.txt` 以通用 CMake 选项组织构建，可生成共享库，并支持测试目标与可选 `cJSON_Utils`。
- `libs/cJSON/tests/CMakeLists.txt` 使用 Unity 生成一组独立测试可执行文件；这些入口依赖可执行文件布局和测试数据目录复制，不涉及 HarmonyOS 专有接口。

## 3. HarmonyOS 业务适配点

- 当前未发现主库源码中必须替换为 HarmonyOS 专有业务接口的逻辑，Phase 4 预期不需要修改 `cJSON.c` 或 `cJSON.h` 的业务实现。
- 当前未发现必须新增 HarmonyOS 平台宏分支的证据，优先沿用现有通用 C/CMake 路径，符合流程中“优先让流程走通”的规则。
- 需要关注的兼容点主要是构建配置而不是业务代码：
  - `ENABLE_LOCALES` 依赖 `localeconv()`；若交叉编译或设备侧运行出现 locale 兼容问题，可在 Phase 5 评估是否通过 CMake 选项关闭。
  - 默认只构建主库；`cJSON_Utils` 是否启用应基于 recipe 预检查和产物要求决定。
- 现阶段可暂时跳过与当前交付目标无关的完整测试矩阵，只保留 `.so` 和至少一个真实可执行测试入口所需的最小接入。

## 4. 可复用测试入口与指导

- 优先复用的上游自带、可独立运行的测试入口：
  - `libs/cJSON/test.c`
  - `libs/cJSON/tests/parse_examples.c`
  - `libs/cJSON/tests/readme_examples.c`
  - `libs/cJSON/tests/misc_tests.c`
- 这些入口属于独立可执行程序，优先级高于单纯 CLI 参数检查，符合仓库对“上游自带、可独立运行测试入口优先”的规则。
- 推荐优先使用的设备侧真实功能路径：
  - 运行由 `test.c` 生成的示例程序，验证 JSON 创建、打印、预分配打印与解析流程。
  - 若启用 `ENABLE_CJSON_TEST`，运行 `parse_examples` 或 `readme_examples`，验证解析与打印回归路径。
- 若 Phase 5 最终只产出示例或测试可执行文件而没有专门 CLI，可直接把这些上游独立程序作为设备侧验证入口；当前库不应记为“无测试用例”。
- 当前未发现比这些独立测试程序更合适的上游 CLI，因此后续不应退化为只跑 `--version` 或类似空验证路径。

## 5. 给 Phase 5 的最小交接摘要

- 构建系统类型：`cmake`
- 是否发现现成 `HPKBUILD`：是
  - `tpc_c_cplusplus/thirdparty/cJSON/HPKBUILD`
  - `tpc_c_cplusplus/community/cJSON/HPKBUILD`
- 是否更适合优先尝试 `lycium`：是
  - 依据：已存在同库现成 recipe，且版本就是 `v1.7.19`，符合 `docs/README.md` 的 lycium-first 规则。
- 是否预计需要 fallback：暂不预设
  - 依据：现成 recipe 已覆盖目标版本，应先做 recipe 预检查、预修正，再执行 lycium。
- 已知高风险依赖或构建障碍：
  - 现成 `HPKBUILD` 当前未启用实际测试，仅在 `check()` 中声明“测试需在设备侧执行”；Phase 5 需要补充真实可执行测试产物与设备侧验证路径。
  - `ENABLE_CJSON_TEST` 默认开启，可能引入大量 Unity 测试目标；Phase 5 需在 recipe 预检查时判断哪些目标保留为设备侧验证入口，哪些可不纳入最终产物。
  - `ENABLE_LOCALES` 依赖 `localeconv()`；若 HarmonyOS 交叉编译或运行时出现兼容性问题，应先在 lycium 预修正中处理，而不是直接 fallback。
