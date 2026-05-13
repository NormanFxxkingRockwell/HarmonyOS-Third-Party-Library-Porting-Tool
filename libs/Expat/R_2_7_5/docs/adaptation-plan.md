# Expat 适配方案

## 1. 项目结构概览

- 核心源码位于 `libs/Expat/expat/lib/`，公共头文件位于 `libs/Expat/expat/lib/expat.h`、`libs/Expat/expat/lib/expat_external.h`。
- 主构建入口位于 `libs/Expat/expat/CMakeLists.txt`，同时存在 `configure.ac`，但 CMake 是更直接的主入口。
- 上游自带可独立运行的工具和示例已存在：
  - `libs/Expat/expat/xmlwf/xmlwf.c`
  - `libs/Expat/expat/examples/elements.c`
  - `libs/Expat/expat/examples/outline.c`
  - `libs/Expat/expat/examples/element_declarations.c`
- 上游自带测试入口已存在：
  - `libs/Expat/expat/tests/runtests.c`
  - `libs/Expat/expat/tests/runtests_cxx.cpp`
  - `libs/Expat/expat/tests/xmltest.sh`

## 2. 平台相关代码识别

- 主库 `lib/` 未发现必须替换为 HarmonyOS 专有接口的明显平台分支，整体以标准 C 为主。
- `xmlwf` 工具存在 Unix/Windows 双实现分流，`libs/Expat/expat/xmlwf/unixfilemap.c` 使用 `mmap`、`fcntl`、`unistd.h`、`sys/stat.h` 等 POSIX 接口；这更像设备侧工具链兼容性问题，不是业务源码适配点。
- 测试与工具路径依赖常见 POSIX 运行时和文件系统能力，但未发现必须新增 `OHOS` 条件编译宏的直接证据。
- 当前未发现 `__OHOS__`、`OHOS` 等专用宏分支，说明 HarmonyOS 适配更可能落在构建参数、recipe 和测试入口选择，而不是主库逻辑替换。

## 3. HarmonyOS 业务适配点

- 当前未发现主库代码必须替换为 HarmonyOS 专用实现的业务适配点。
- 当前未发现必须新增 HarmonyOS 平台宏分支才能编译主库的证据。
- 当前建议在 Phase 4 保持 `libs/Expat/` 上游源码不变，优先通过 Phase 5 的构建配置、recipe 升级和测试入口回收完成移植。
- 若 Phase 5 暴露问题，优先按文档归类为：
  - recipe/HPKBUILD 问题
  - 构建系统/工具链问题
  - 测试入口运行环境问题
  而不是先假定为业务源码适配问题。

## 4. 建议修改清单

- Phase 4 预计不修改 `libs/Expat/` 业务源码。
- Phase 5 应优先处理已有 recipe `tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD` 的升级和预修正：
  - 版本从 `R_2_5_0` 升级到目标 `R_2_7_5`
  - 校正 `packagename`、下载包名、`builddir`
  - 重新生成 `SHA512SUM`
  - 确认 `EXPAT_BUILD_TOOLS`、`EXPAT_BUILD_EXAMPLES`、`EXPAT_BUILD_TESTS` 相关目标是否被 recipe 关闭
  - 补齐 binary install 或后续回收路径

## 5. 风险与假设

- 已发现现成 recipe：`tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD`，但其目标版本是 `R_2_5_0`，与任务表 `2.7.5` 不一致。
- 依据 `docs/10-build-system-detect.md` 和 `docs/11-cmake-build.md`，仅因 recipe 版本或包名不一致，不能直接 fallback，必须先完成一轮 recipe 升级与预修正。
- `xmlwf` 使用 `mmap` 的 Unix 文件映射实现，设备侧运行可能受文件系统或运行环境影响；这会影响测试入口优先级，但不构成直接 fallback 依据。
- `xmltest.sh` 依赖外部 W3C XML 测试集，不适合作为当前设备侧首选验证入口。

## 6. 可复用测试入口与指导

- 上游自带、可独立运行的优先候选入口：
  - `xmlwf`：上游 CLI，可做真实 XML 解析能力校验
  - `examples/elements.c`：标准输入读 XML 并输出元素树，依赖简单，适合作为设备侧轻量验证
  - `examples/outline.c`
  - `examples/element_declarations.c`
  - `tests/runtests.c` 与 `tests/runtests_cxx.cpp`：存在，但依赖完整测试构建链和更多测试支撑文件，优先级低于 examples
- 不建议优先使用 `tests/xmltest.sh` 作为设备侧入口，因为它依赖额外 XML 测试数据集和 shell 驱动环境。
- 若 examples 可成功构建，优先回收 `elements` 作为设备侧测试 binary。
- 若 examples 不适合回收，再使用 `xmlwf` 做 CLI 能力校验；CLI 校验必须覆盖真实解析路径，例如读取 XML 文件或标准输入 XML，而不是只跑 `--version`。
- 推荐优先测试命令：
  - `echo '<root><a>1</a></root>' | ./elements`
  - `./xmlwf sample.xml`

## 7. 给 Phase 5 的最小交接摘要

- 构建系统类型：`cmake`
- 是否发现现成 `HPKBUILD`：是，`tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD`
- 是否更适合优先尝试 `lycium`：是；已有同库 recipe，且主库构建系统清晰
- 是否预计需要 fallback：暂不直接判断，需要先完成 recipe 预检查、预修正并实际尝试 `lycium`
- 已知高风险依赖或构建障碍：
  - 现成 recipe 版本落后于目标版本
  - 现成 recipe 使用镜像 zip 包和旧 `SHA512SUM`
  - 测试入口中 `xmltest.sh` 依赖外部测试数据，不适合直接作为设备侧验证主入口
